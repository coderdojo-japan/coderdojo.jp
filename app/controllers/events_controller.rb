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
end
