class EventsController < ApplicationController
  def show
    @url             = request.url
    @upcoming_events = UpcomingEvent.group_by_region_and_date
  end
end
