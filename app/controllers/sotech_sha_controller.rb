class SotechShaController < ApplicationController
  def index
    chapter = params[:chapter]
    redirect_to "/#{chapter}"
  end
end
