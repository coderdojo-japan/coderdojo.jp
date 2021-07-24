class PodcastsController < ApplicationController
  def index
    @title         = 'DojoCast'
    @description   = 'CoderDojo に関わる人々をハイライトする Podcast 📻✨'
    @episodes      = Podcast.order(:published_date).reverse
    @url           = request.url

    # GET /podcasts.rss
    @art_work_url  = "https://coderdojo.jp/podcasts/cover.jpg"
    @author        = "一般社団法人 CoderDojo Japan"
    @copyright     = "Copyright © 2012-#{Time.current.year} #{@author}"
    @anchorfm_user = 'coderdojo-japan'

    respond_to do |format|
      format.html
      format.rss  { render 'feed', layout: false }
    end
  end

  def show
    @episode = Podcast.find_by(id: params[:id])
    redirect_to root_url unless @episode.exists?

    @title   = "#DojoCast " + @episode.title
    @content = Kramdown::Document.new(@episode.content, input: 'GFM').to_html
    @url     = request.url
  end
end
