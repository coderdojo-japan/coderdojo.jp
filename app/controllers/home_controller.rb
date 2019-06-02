class HomeController < ApplicationController
  def show
    @dojo_count        = Dojo.active_dojos_count
    @regions_and_dojos = Dojo.group_by_region_on_active
    @upcoming_events   = UpcomingEvent.group_by_date
  end
end
