class SpacesController < ApplicationController
  # http_basic_authenticate_with name: ENV['SPACES_BASIC_AUTH_NAME'], password: ENV['SPACES_BASIC_AUTH_PASSWORD'] if Rails.env.production?

  def index
    @dojo_count        = Dojo.count
    @regions_and_dojos = Dojo.group_by_region
  end
end
