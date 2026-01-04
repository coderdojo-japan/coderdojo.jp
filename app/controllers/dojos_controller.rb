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
    dojos_scope.includes(:prefecture).order_by_active_status.order(order: :asc).each do |dojo|
      # 年が選択されている場合は、その年末時点でのアクティブ状態を判定
      # 選択されていない場合は、現在の is_active を使用
      is_active_at_selected_time = if @selected_year
        # その年末時点でアクティブだったかを判定
        # inactivated_at が nil（まだアクティブ）または選択年より後に非アクティブ化
        dojo.inactivated_at.nil? || dojo.inactivated_at > Time.zone.local(@selected_year).end_of_year
      else
        dojo.active?
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
        inactivated_at: dojo.inactivated_at,  # CSV用に追加
      }
    end

    # counter合計を計算（/statsとの照合用）
    @counter_sum = @dojos.sum { |d| d[:counter] }

    # 情報メッセージを設定
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
    else
      # 全期間表示時の情報メッセージ
      flash.now[:inline_info] = "全期間の道場を表示中（非アクティブ含む）"
    end

    respond_to do |format|
      format.html { render :index }  # => app/views/dojos/index.html.erb
      format.json { render json: @dojos }
      format.csv do
        # ファイル名を年に応じて設定
        filename = if @selected_year
          "dojos_#{@selected_year}.csv"
        else
          "dojos_all.csv"
        end
        send_data render_to_string, type: :csv, filename: filename
      end
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

  # GET /dojos/activity
  # 道場の活動状況を表示（旧 /events/latest から移行）
  def activity
    # ビューで使用するための閾値をインスタンス変数に設定（モデルから取得）
    @inactive_threshold = Dojo::INACTIVE_THRESHOLD_IN_MONTH

    @latest_event_by_dojos = []

    # アクティブな道場と非アクティブな道場を両方取得
    # アクティブな道場を先に、非アクティブな道場を後に表示
    dojos = Dojo.active.to_a + Dojo.inactive.to_a

    dojos.each do |dojo|
      link_in_note = dojo.note.match(URI.regexp)
      # YYYY-MM-DD、YYYY/MM/DD、または YYYY年MM月DD日 形式の日付を抽出
      date_in_note = dojo.note.match(/(\d{4}-\d{1,2}-\d{1,2}|\d{4}\/\d{1,2}\/\d{1,2}|\d{4}年\d{1,2}月\d{1,2}日)/)

      latest_event = dojo.event_histories.newest.first

      @latest_event_by_dojos << {
        id:         dojo.id,
        name:       dojo.name,
        note:       dojo.note,
        url:        dojo.url,
        created_at: dojo.created_at,  # 掲載日（/dojos と同じ）
        is_active:  dojo.active?,   # アクティブ状態を追加

        # 直近の開催日（イベント履歴がある場合のみ）
        latest_event_at:  latest_event&.evented_at,
        latest_event_url: latest_event&.event_url,

        # note内の日付とリンク（fallback用）
        note_date: parse_date_from_note(date_in_note),
        note_link: link_in_note&.to_s
      }
    end

    # アクティブな道場と非アクティブな道場を分けてソート
    active_dojos   = @latest_event_by_dojos.select { |d| d[:is_active] }
    inactive_dojos = @latest_event_by_dojos.reject { |d| d[:is_active] }

    # それぞれのグループ内でソート
    active_dojos.sort_by! do |dojo|
      sort_date = dojo[:latest_event_at] || dojo[:note_date] || dojo[:created_at]
      [sort_date, dojo[:order]]
    end

    # 非アクティブな道場は最新の開催日から古い順（降順）にソート
    inactive_dojos.sort_by! do |dojo|
      sort_date = dojo[:latest_event_at] || dojo[:note_date] || dojo[:created_at]
      [-sort_date.to_i, dojo[:order]]  # マイナスを付けて降順にする
    end

    # アクティブな道場を先に、非アクティブな道場を後に
    @latest_event_by_dojos = active_dojos + inactive_dojos
  end

  private

  def parse_date_from_note(date_match)
    return nil if date_match.nil?

    date_string = date_match.to_s

    # 日本語形式の日付を標準形式に変換（例: 2025年8月24日 → 2025-08-24）
    if date_string.include?('年')
      date_string = date_string.gsub(/(\d{4})年(\d{1,2})月(\d{1,2})日/, '\1-\2-\3')
    end

    Time.zone.parse(date_string)
  rescue ArgumentError
    nil
  end
end
