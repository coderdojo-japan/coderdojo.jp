class Sotechsha2PagesController < ApplicationController
  def index; end
  
  def show
    render "sotechsha2_pages/#{params[:page]}"
  end
end
