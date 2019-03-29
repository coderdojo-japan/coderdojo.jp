class PodcastsController < ApplicationController
  def index
    @title          = 'DojoCast'
    @description    = 'Highlight people around CoderDojo communities by Podcast 📻✨'
    @episodes       = Podcast.all.sort_by{|episode| episode.published_at }
    @url            = request.url
    @next_live_date = ENV['NEXT_LIVE_DATE'] || '未定'

    # For .rss format
    @art_work_url = "https://coderdojo.jp/podcasts/cover.jpg"
    @author       = "一般社団法人 CoderDojo Japan"
    @copyright    = "Copyright © 2012-#{Time.current.year} #{@author}"
    @base_url     = request.base_url

    respond_to do |format|
      format.html
      format.rss  { render "feed", :layout => false }
    end
  end

  def show
    @episode  = Podcast.new(params[:id])
    redirect_to root_url unless @episode.exists?
    @title    = "#DojoCast " + @episode.title
    @filename = @episode.filename
    @content  = Kramdown::Document.new(@episode.content, input: 'GFM').to_html
    @url      = request.url
  end

end
