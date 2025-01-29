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
    if @episode.nil?
      flash[:warning] = '該当する番組が見つかりませんでした 💦'
      return redirect_to podcasts_path
    end

    @url     = request.url
    @title   = @episode.title.split('-').last.strip
    @date    = @episode.published_date.strftime("%Y年%-m月%-d日（#{Podcast::WDAY2JAPANESE[@episode.published_date.wday]}）")
    @content = Kramdown::Document.new(
                                  self.convert_shownote(@episode.content),
                                  input: 'GFM').to_html
  end

  private

  def convert_shownote(content)
    youtube_id = @episode.content.match(/watch\?v=((\w)*)/)[1]

    shownote = <<~HTML
      <h2 id='shownote'>
        <a href='#shownote'>🎤</a>
        Shownote
        <small>(話したこと)</small>
      </h2>
    HTML

    content.gsub!(/(#+) Shownote/) { shownote }
    return content unless content.match?(Podcast::TIMESTAMP_REGEX)

    content.gsub!(Podcast::TIMESTAMP_REGEX) do
        t = $1
        t = (t.size ==  '0:00'.size) ?   '0' + t : t
        t = (t.size == '00:00'.size) ? '00:' + t : t
        t = Time.parse(t).seconds_since_midnight.to_i
        "- [#{$1}](https://youtu.be/#{youtube_id}?t=#{t}) &nbsp; "
    end
  end
end
