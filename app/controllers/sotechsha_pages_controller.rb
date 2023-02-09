class SotechshaPagesController < ApplicationController
  def index; end
  
  def show
    render "sotechsha_pages/#{params[:page]}"
  end
end
