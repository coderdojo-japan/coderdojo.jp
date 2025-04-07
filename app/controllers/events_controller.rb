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
      latest_event = dojo.event_histories.newest.first

      link_in_note = dojo.note.match(URI.regexp)
      date_in_note = dojo.note.match(/(\d{4}-\d{1,2}-\d{1,2})/) # YYYY-MM-DD
      last_session_link = link_in_note.nil? ? dojo_path(dojo.id) : link_in_note
      last_session_date = date_in_note.nil? ? dojo.created_at    : Time.zone.parse(date_in_note.to_s)
      @latest_event_by_dojos << {
        id:   dojo.id,
        name: dojo.name,
        note: dojo.note,
        url:  dojo.url,
        has_event_histories: latest_event.nil?,

        # 過去のイベント開催データが無ければ、note 内にある日付または掲載日を表示
        event_at:  latest_event.nil? ?
          last_session_date.strftime("%Y-%m-%d") :
          latest_event.evented_at.strftime("%Y-%m-%d"),

        # 過去のイベント開催データが無ければ、note 内にあるリンクまたは個別統計ページを表示
        event_url: latest_event.nil? ?
          last_session_link.to_s :
          latest_event.event_url
      }
    end

    # Sort by older events first && older Dojo ID first if same event date.
    @latest_event_by_dojos.sort_by!{ |dojo| [dojo[:event_at], dojo[:id]] }
  end
end
