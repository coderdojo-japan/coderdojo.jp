class PodcastsController < ApplicationController
  def index
    @title = 'DojoCast'
    @desc  = 'Highlight people around CoderDojo communities by Podcast 📻✨'
    @episodes = Podcast.all.sort_by{|episode| episode.filename.rjust(3, '0')}
    @url      = request.url
  end

  def show
    @episode  = Podcast.new(params[:id])
    redirect_to root_url unless @episode.exists?
    @title    = "#DojoCast " + @episode.title
    @filename = @episode.filename
    @content  = Kramdown::Document.new(@episode.content, input: 'GFM').to_html
    @url      = request.url
  end

  def feed
    @episodes   = Podcast.all.sort_by{|episode| episode.filename.rjust(3, '0')}
    @domainname = request.base_url
    respond_to do |format|
      format.rss { render :layout => false }
    end
  end
end
