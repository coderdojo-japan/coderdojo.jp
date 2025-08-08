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
        end_of_year = Time.zone.local(@selected_year).end_of_year
        
        # その年末時点でアクティブだった道場を取得
        dojos_scope = Dojo.active_at(end_of_year)
        @page_title = "#{@selected_year}年末時点のCoderDojo一覧"
        
        # 成功メッセージもinline_で表示
        flash.now[:inline_info] = "#{@selected_year}年末時点のアクティブな道場を表示中"
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
