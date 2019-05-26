require 'factory_bot'

FactoryBot.define do
  factory :upcoming_event do
    # dojo_id
    dojo_name    { 'Dojo Name' }
    service_name { :connpass }
    event_id     { '1234' }
    event_url    { 'http:/www.aaa.com/events/1224' }
    event_at     { '2019-05-01 10:00'.in_time_zone }
    participants { 1 }
  end
end

