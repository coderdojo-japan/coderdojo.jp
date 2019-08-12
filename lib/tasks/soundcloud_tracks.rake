namespace :soundcloud_tracks do
  desc 'SoundCloud から podcast データ情報を取得し登録'
  task upsert: :environment do
    logger = ActiveSupport::Logger.new('log/soundcloud_tracks.log')
    console = ActiveSupport::Logger.new(STDOUT)
    logger.extend ActiveSupport::Logger.broadcast(console)

    logger.info('==== START soundcloud_tracks:upsert ====')

    client = SoundCloud.new(client_id: ENV['SOUNDCLOUD_CLIENT_ID'])
    tracks = client.get('/users/626746926/tracks', limit: 100).map(&:deep_symbolize_keys)

    if tracks.length.zero?
      logger.info('no track')
      logger.info('==== END soundcloud_tracks:upsert ====')
      return true
    end

    SoundCloudTrack.transaction do
      tracks.sort_by { |d| d[:id] }.each do |d|
        track = SoundCloudTrack.find_by(track_id: d[:id])
        unless track
          is_new = true
          track = SoundCloudTrack.new(track_id: d[:id])
        end
        if d[:release_year] && d[:release_month] && d[:release_day]
          published_date = "#{d[:release_year]}-#{d[:release_month]}-#{d[:release_day]}".to_date
        else
          raise 'No Release Date'
        end
        track.update!(
          title:                 d[:title],
          description:           d[:description],
          original_content_size: d[:original_content_size],
          duration:              Time.at(d[:duration]/1000).utc.strftime('%H:%M:%S'),
          tag_list:              d[:tag_list],
          download_url:          d[:download_url],
          permalink:             d[:permalink],
          permalink_url:         d[:permalink_url],
          uploaded_at:           d[:created_at],
          published_date:        published_date
        )
        logger.info("added [#{track.id}] #{track.title}") if is_new
      end
    end
    logger.info('==== END soundcloud_tracks:upsert ====')
    true
  end
end
