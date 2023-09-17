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
    Dojo.active.each do |dojo|
      if dojo.event_histories.empty?
        @latest_event_by_dojos << {
          name: dojo.name,
          url:  dojo.url,
          event_at: '2000-01-23',
          event_url: nil
        }
      else
        @latest_event_by_dojos << {
          name: dojo.name,
          url:  dojo.url,
          event_at:  dojo.event_histories.last.evented_at.strftime("%Y-%m-%d"),
          event_url: dojo.event_histories.last.event_url.include?('dummy.url') ?
            "https://www.facebook.com/#{dojo.event_histories.last.service_group_id}/events" :
            dojo.event_histories.last.event_url
        }
      end
    end

    @latest_event_by_dojos.sort_by!{|dojo| dojo[:event_at]}
  end
end
