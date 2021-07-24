FactoryBot.define do
  factory :podcast, class: Podcast do
    title          { 'title' }
    description    { 'description' }
    content_size   { 0 }
    duration       { 0 }
    permalink      { 'title' }
    permalink_url  { 'https://aaa.bbb/title' }
    enclosure_url  { 'https://ccc.ddd/title.mp3' }
    published_date { Time.zone.today }
  end
end
