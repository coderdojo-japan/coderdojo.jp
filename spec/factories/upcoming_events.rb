require 'factory_bot'

FactoryBot.define do
  factory :upcoming_event do
    service_name { :connpass }
    event_id     { '1234' }
    event_title  { 'event title' }
    event_url    { 'http:/www.aaa.com/events/1224' }
    event_at     { '2019-05-01 10:00'.in_time_zone }
    event_end_at { '2019-05-01 13:00'.in_time_zone }
    participants { 1 }
    event_update_at { '2019-05-01 09:00'.in_time_zone }
    address { '東京都新宿区高田馬場１丁目２８−１０' }
    place { 'CASE Shinjuku 三慶ビル 4階' }
    limit { 10 }
  end
end

