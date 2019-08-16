class EventsController < ApplicationController
  def index
    @url             = request.url
    @upcoming_events = UpcomingEvent.group_by_prefecture

    respond_to do |format|
      format.html
      format.json { render json: @upcoming_events }
    end
  end
end
