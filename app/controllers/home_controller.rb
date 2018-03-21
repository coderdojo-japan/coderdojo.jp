class HomeController < ApplicationController
  def show
    @dojo_count        = Dojo.count
    @regions_and_dojos = Dojo.group_by_region
  end
end
