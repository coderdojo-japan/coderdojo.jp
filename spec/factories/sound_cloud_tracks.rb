FactoryBot.define do
  factory :sound_cloud_track do
    track_id              { 123 }
    title                 { 'title' }
    description           { 'description' }
    original_content_size { 0 }
    duration              { 0 }
    tag_list              { 'coderdojo' }
    download_url          { 'http://aaa.bbb/123/download' }
    permalink             { 'title' }
    permalink_url         { 'http://aaa.bbb/title' }
    uploaded_at           { '2019/01/01 09:00:00'.in_time_zone }
  end
end
