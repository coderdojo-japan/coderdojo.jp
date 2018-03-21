class SpacesController < ApplicationController
  def index
    @dojo_count        = Dojo.count
    @regions_and_dojos = Dojo.group_by_region
  end
end
