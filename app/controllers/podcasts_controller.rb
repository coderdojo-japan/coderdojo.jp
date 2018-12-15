class PodcastsController < ApplicationController
  def index
    @title = 'DojoCast'
    @desc  = 'Highlight people around CoderDojo communities by Podcast 📻✨'
    @episodes  = Podcast.all
    @url       = request.url
  end

  def show
    @episode  = Podcast.new(params[:id])
    redirect_to root_url unless @episode.exists?
    @filename = @episode.filename
    @content  = Kramdown::Document.new(@episode.content, input: 'GFM').to_html
    @url      = request.url
  end
end
