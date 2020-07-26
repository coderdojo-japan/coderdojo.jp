FactoryBot.define do
  factory :podcast, class: Podcast do
    track_id       { 123 }
    title          { 'title' }
    description    { 'description' }
    content_size   { 0 }
    duration       { 0 }
    permalink      { 'title' }
    permalink_url  { 'http://aaa.bbb/title' }
    published_date { Time.zone.today }
  end
end
