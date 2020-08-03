require 'rss'

namespace :podcasts do
  desc 'SoundCloud から Podcast データ情報を取得して登録'
  task upsert: :environment do
    user_id     = '626746926'
    logger      = ActiveSupport::Logger.new('log/podcasts.log')
    console     = ActiveSupport::Logger.new(STDOUT)
    logger.extend ActiveSupport::Logger.broadcast(console)

    logger.info('==== START podcasts:upsert ====')

    SOUNDCLOUD_RSS = Rails.env.test? ?
      'soundcloud_sample.rss' :
      'https://feeds.soundcloud.com/users/soundcloud:users:626746926/sounds.rss'
    rss = RSS::Parser.parse(SOUNDCLOUD_RSS, false)

    if rss.items.length.zero?
      logger.info('No track exists. Maybe failed to set RSS URL?')
      exit
    end

    Podcast.transaction do
      rss.items.each_with_index do |item, index|
        track_id = item.guid.content.split('/').last.to_i
        episode  = Podcast.find_by(track_id: track_id) || Podcast.new(track_id: track_id)

        episode.new_record? ?
          logger.info("Creating: #{item.title   }") :
          logger.info("Updating: #{episode.title}")

        params = {
            title:          item.title,
            description:    item.description,
            content_size:   item.enclosure.length,
            duration:       item.itunes_duration.content,
            permalink:      item.link.split('/').last,
            permalink_url:  item.link,
            published_date: item.pubDate.to_date,
        }
        params[:id] = item.title.split('-').first.to_i if episode.new_record?

        episode.update!(params)
      end
    end

    logger.info('==== END podcasts:upsert ====')
    true
  end
end
