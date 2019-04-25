namespace :sound_cloud_tracks do
  desc 'SoundCloud から podcast データ情報を取得し登録'
  task upsert: :environment do
    client = SoundCloud.new(client_id: ENV['SOUND_CLOUD_CLIENT_ID'])
    tracks = client.get("/users/#{ENV['SOUND_CLOUD_CODERDOJO_USER_ID']}/tracks").map(&:deep_symbolize_keys!)

    return true if tracks.length.zero?

    SoundCloudTrack.transaction do
      tracks.each do |d|
        track = SoundCloudTrack.find_or_initialize_by(track_id: d[:id])
        track.update!(
          title:                 d[:title],
          description:           d[:description],
          original_content_size: d[:original_content_size],
          duration:              Time.at(d[:duration]/1000).utc.strftime('%H:%M:%S'),
          tag_list:              d[:tag_list],
          download_url:          d[:download_url],
          permalink_url:         d[:permalink_url],
          uploaded_at:           d[:created_at].in_time_zone
        )
      end
    end
    true
  end
end
