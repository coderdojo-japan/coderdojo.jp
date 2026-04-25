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
    @youtube_id = @episode.content.match(Podcast::REGEX_YOUTUBE_ID)[1]
    @content = Kramdown::Document.new(
                                  self.convert_shownote(@episode.content),
                                  input: 'GFM').to_html
  end

  private

  def convert_shownote(content)
    shownote = <<~HTML
      <h2 id='shownote'>
        <a href='#shownote'>🎤</a>
        Shownote
        <small>(話したこと)</small>
      </h2>
    HTML
    content.gsub!(/(#+) Shownote/) { shownote }

    return content unless content.match?(Podcast::REGEX_YOUTUBE_ID)
    youtube_id = content.match(Podcast::REGEX_YOUTUBE_ID)[1]
    embed = render_to_string(partial: 'podcasts/youtube_embed', locals: { youtube_id: youtube_id })
    content.gsub!(/<a[^>]+>\s*<img[^>]+Cover Photo[^>]*>\s*<\/a>/m, embed)
    return content unless content.match?(Podcast::REGEX_TIMESTAMP)
    content.gsub!(Podcast::REGEX_TIMESTAMP) do
        original_t = $1
        parts = original_t.split(':')

        # タイムスタンプをh:m:s形式に変換
        if parts.size == 3
          # 00:00:00 形式
          h, m, s = parts
          t = "#{h}h#{m}m#{s}s"
        elsif parts.size == 2
          # 00:00 形式
          m, s = parts
          t = "#{m}m#{s}s"
        else
          # それ以外（通常は来ないはず）
          t = original_t
        end

        "[#{original_t}](https://youtu.be/#{youtube_id}?t=#{t}) &nbsp; "
    end
  end
end
