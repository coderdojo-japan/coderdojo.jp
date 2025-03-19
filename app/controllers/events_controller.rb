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
    @url = request.url
    @latest_event_by_dojos = []
    @active_dojos_verified = [
      '和歌山', '市川真間', '泉', '石垣', '南紀田辺', '三好', '市川', 'ひばりヶ丘', '伊勢',
      '徳島', '柏', '富山', 'ももち', '木曽', '熊本'
    ]
    Dojo.active.each do |dojo|
      latest_event = dojo.event_histories.newest.first
      if @active_dojos_verified.include?(dojo.name) or latest_event.nil?
        @latest_event_by_dojos << {
          id:   dojo.id,
          name: dojo.name,
          note: dojo.note,
          url:  dojo.url,
          event_at: '2000-01-23',
          event_url: nil
        }
      else
        @latest_event_by_dojos << {
          id:   dojo.id,
          name: dojo.name,
          note: dojo.note,
          url:  dojo.url,
          event_at:  latest_event.evented_at.strftime("%Y-%m-%d"),
          event_url: latest_event.event_url.include?('dummy.url') ?
            "https://www.facebook.com/#{latest_event.service_group_id}/events" :
            latest_event.event_url
        }
      end
    end

    # Sort by older events first && older Dojo ID first if same event date.
    @latest_event_by_dojos.sort_by!{ |dojo| [dojo[:event_at], dojo[:id]] }
  end
end
