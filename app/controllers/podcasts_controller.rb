class PodcastsController < ApplicationController
  def index
    @title          = 'DojoCast'
    @description    = 'Highlight people around CoderDojo community by Podcast.'
    @episodes       = SoundCloudTrack.order(:published_date)
    @url            = request.url
    @next_live_date = ENV['NEXT_LIVE_DATE'] || '未定'

    # For .rss format
    @art_work_url    = "https://coderdojo.jp/podcasts/cover.jpg"
    @author          = "一般社団法人 CoderDojo Japan"
    @copyright       = "Copyright © 2012-#{Time.current.year} #{@author}"
    @soundcloud_user = 'coderdojo-japan'

    respond_to do |format|
      format.html
      format.rss  { render 'feed', layout: false }
    end
  end

  def show
    @episode = SoundCloudTrack.find_by(id: params[:id])
    redirect_to root_url unless @episode.exists?

    @title   = "#DojoCast " + @episode.title
    @content = Kramdown::Document.new(@episode.content, input: 'GFM').to_html
    @url     = request.url
  end
end
