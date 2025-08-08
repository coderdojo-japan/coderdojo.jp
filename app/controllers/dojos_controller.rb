class DojosController < ApplicationController

  # GET /dojos[.html|.json|.csv]
  def index
    # yearパラメータがある場合の処理
    if params[:year].present?
      begin
        year = params[:year].to_i
        # 有効な年の範囲をチェック
        unless year.between?(2012, Date.current.year)
          flash[:inline_alert] = "指定された年は無効です。2012年から#{Date.current.year}年の間で指定してください。"
          return redirect_to dojos_path(anchor: 'table')
        end
        
        @selected_year = year
        year_end = Time.zone.local(@selected_year).end_of_year
        
        # その年末時点でアクティブだった道場を取得
        dojos_scope = Dojo.active_at(year_end)
        @page_title = "#{@selected_year}年末時点のCoderDojo一覧"
      rescue ArgumentError
        flash[:inline_alert] = "無効な年が指定されました"
        return redirect_to dojos_path(anchor: 'table')
      end
    else
      # yearパラメータなしの場合（既存の実装そのまま）
      dojos_scope = Dojo.all
    end
    
    @dojos = []
    dojos_scope.includes(:prefecture).order(is_active: :desc, order: :asc).each do |dojo|
      # 年が選択されている場合は、その年末時点でのアクティブ状態を判定
      # 選択されていない場合は、現在の is_active を使用
      is_active_at_selected_time = if @selected_year
        # その年末時点でアクティブだったかを判定
        # inactivated_at が nil（まだアクティブ）または選択年より後に非アクティブ化
        dojo.inactivated_at.nil? || dojo.inactivated_at > Time.zone.local(@selected_year).end_of_year
      else
        dojo.is_active
      end
      
      @dojos << {
        id:          dojo.id,
        url:         dojo.url,
        name:        dojo.name,
        logo:        root_url + dojo.logo[1..],
        order:       dojo.order,
        counter:     dojo.counter,
        is_active:   is_active_at_selected_time,
        prefecture:  dojo.prefecture.name,
        created_at:  dojo.created_at,
        description: dojo.description,
      }
    end
    
    # counter合計を計算（/statsとの照合用）
    @counter_sum = @dojos.sum { |d| d[:counter] }
    
    # 年が選択されている場合、統計情報を含むメッセージを設定
    if @selected_year
      # /statsページと同じ計算方法を使用
      # 開設数 = その年に新規開設されたDojoのcounter合計
      year_begin = Time.zone.local(@selected_year).beginning_of_year
      year_end = Time.zone.local(@selected_year).end_of_year
      new_dojos_count = Dojo.where(created_at: year_begin..year_end).sum(:counter)
      
      # 合計数 = その年末時点でアクティブだったDojoのcounter合計
      total_dojos_count = Dojo.active_at(year_end).sum(:counter)
      
      # 表示用の日付テキスト
      display_date = "#{@selected_year}年末"
      display_date = Date.current.strftime('%Y年%-m月%-d日') if @selected_year == Date.current.year
      
      flash.now[:inline_info] = "#{display_date}時点のアクティブな道場を表示中<br>（開設数: #{new_dojos_count} / 合計数: #{total_dojos_count}）".html_safe
    end

    respond_to do |format|
      format.html { render :index }  # => app/views/dojos/index.html.erb
      format.json { render json: @dojos }
      format.csv  { send_data render_to_string, type: :csv }
    end
  end

  # GET /dojos/:id
  def show
    @dojo = Dojo.find(params[:id])
    @event_histories = @dojo.event_histories.order(evented_at: :DESC)
      .select(:evented_at, :participants, :event_url)

    respond_to do |format|
      format.html
      format.json { render json: @event_histories.as_json(except: [:id]) }
      format.csv  { send_data render_to_string, type: :csv }
    end
  end
end
