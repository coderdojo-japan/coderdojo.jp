class EventsController < ApplicationController
  def index
    @url             = request.url
    @upcoming_events = UpcomingEvent.group_by_prefecture_and_date
  end
end
