class EventsController < ApplicationController
  def index
    @url             = request.url
    @upcoming_events = UpcomingEvent.group_by_prefecture
    @pokemon_events  = UpcomingEvent.group_by_keyword('ポケモン').order(event_at: :ASC)
    all_events       = params[:all_events].eql?('true')

    respond_to do |format|
      format.html
      format.json {
        # DojoMap: https://map.coderdojo.jp
        render json: UpcomingEvent.for_dojo_map(all_events)
      }
    end
  end

  def latest
    # 現在はノートで細かな確認ができるため不要? (念のため残しています)
    # @active_dojos_verified = [
    #  '和歌山', '市川真間', '泉', '石垣', '南紀田辺', '三好', '市川', 'ひばりヶ丘', '伊勢',
    #  '徳島', '柏', '富山', 'ももち', '木曽', '熊本'
    # ]
    @latest_event_by_dojos = []
    Dojo.active.each do |dojo|
      link_in_note = dojo.note.match(URI.regexp)
      date_in_note = dojo.note.match(/(\d{4}-\d{1,2}-\d{1,2})/) # YYYY-MM-DD
      last_session_link = link_in_note.nil? ? dojo_path(dojo.id) : link_in_note.to_s
      last_session_date = date_in_note.nil? ? dojo.created_at    : Time.zone.parse(date_in_note.to_s)

      latest_event    = dojo.event_histories.newest.first
      latest_event_at = latest_event.nil? ? Time.zone.parse('2000-01-23') : latest_event.evented_at
      @latest_event_by_dojos << {
        id:   dojo.id,
        name: dojo.name,
        note: dojo.note,
        url:  dojo.url,
        has_event_histories: latest_event.nil?,

        # 過去のイベント開催日と note 内の日付を比較し、新しい方の日付を表示
        event_at: (latest_event_at < last_session_date) ?
          last_session_date.strftime("%Y-%m-%d") :
          latest_event.evented_at.strftime("%Y-%m-%d"),

        # 過去のイベント開催日と note 内の日付を比較し、新しい方のリンクを表示
        event_url: (latest_event_at < last_session_date) ?
          last_session_link :
          latest_event.event_url
      }
    end

    # Sort by older events first && older Dojo ID first if same event date.
    @latest_event_by_dojos.sort_by!{ |dojo| [dojo[:event_at], dojo[:id]] }
  end
end
