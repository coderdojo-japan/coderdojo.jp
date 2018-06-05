class HomeController < ApplicationController
  def show
    @dojo_count        = Dojo.active.count
    @regions_and_dojos = Dojo.group_by_region_on_active
  end
end
