RSpec.shared_context 'Use stub connection of Faraday' do
  let(:stub_connection) do
    Faraday.new do |f|
      f.response :json, :content_type => /\bjson$/
      f.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
        # connpass
        stub.get('/event/') do |env|
          if env.params["series_id"] == '9876,9877'
            multiple_series_ids_response
          else
            connpass_response
          end
        end

        # doorkeeper
        stub.get('/events') { doorkeeper_response }
        stub.get('/groups/5555/events') { doorkeeper_response }
      end
    end
  end

  before do
    allow_any_instance_of(EventService::Client).to receive(:connection_for).and_return(stub_connection)
  end
end

RSpec.shared_context 'Use stubs for Connpass' do
  include_context 'Use stub connection of Faraday'

  # response for multiple series_ids 9876 and 9877
  let(:multiple_series_ids_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '{"results_returned": 2, "events": [{"event_url": "https://coderdojo-okutama.connpass.com/event/12345/", "event_type": "participation", "owner_nickname": "nalabjp", "series": {"url": "https://coderdojo-okutama.connpass.com/", "id": 9876, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "event_id": 12345, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},{"event_url": "https://coderdojo-okutama.connpass.com/event/12346/", "event_type": "participation", "owner_nickname": "nalabjp", "series": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "event_id": 12346, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"}], "results_start": 200, "results_available": 518}'
    ]
  end

  # response for single series_id 9876, and for search
  let(:connpass_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '{"results_returned": 1, "events": [{"event_url": "https://coderdojo-okutama.connpass.com/event/12345/", "event_type": "participation", "owner_nickname": "nalabjp", "series": {"url": "https://coderdojo-okutama.connpass.com/", "id": 9876, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "event_id": 12345, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"}], "results_start": 200, "results_available": 518}'
    ]
  end
end

RSpec.shared_context 'Use stubs for Doorkeeper' do
  include_context 'Use stub connection of Faraday'

  let(:doorkeeper_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '[{"event":{"title":"CoderDojo title","id":1234,"starts_at":"2017-05-28T01:00:00.000Z","ends_at":"2017-05-28T04:00:00.000Z","venue_name":"奥多摩町","address":"奥多摩町","lat":"35.801763000000","long":"139.087656000000","ticket_limit":30,"published_at":"2017-04-22T03:43:04.000Z","updated_at":"2017-05-10T11:31:21.810Z","group":5555,"banner":null,"description":"CoderDojo description","public_url":"https://coderdojo-okutama.doorkeeper.jp/events/8888","participants":12,"waitlisted":0}}]'
    ]
  end
end

RSpec.shared_context 'Use stubs UpcomingEvents for Connpass' do
  include_context 'Use stub connection of Faraday'

  let(:connpass_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '{"results_returned": 1, "events": [{"event_url": "https://coderdojo-okutama.connpass.com/event/12345/", "event_type": "participation", "owner_nickname": "nalabjp", "series": {"url": "https://coderdojo-okutama.connpass.com/", "id": 9876, "title": "CoderDojo series"}, "updated_at": "' +
        "#{Time.zone.today}T14:59:30+09:00" + '", "lat": "35.801763000000", "started_at": "' +
        "#{Time.zone.today + 1.month}T13:00:00+09:00" + '", "hash_tag": "CoderDojo", "title": "CoderDojo title", "event_id": 12345, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "' +
        "#{Time.zone.today + 1.month}T15:00:00+09:00" + '", "place": "Tokyo"}], "results_start": 200, "results_available": 518}'
    ]
  end
end

RSpec.shared_context 'Use stubs UpcomingEvents for Doorkeeper' do
  include_context 'Use stub connection of Faraday'

  let(:doorkeeper_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '[{"event":{"title":"CoderDojo title","id":1234,"starts_at":"' +
           "#{Time.zone.today + 1.month}T01:00:00.000Z" + '","ends_at":"' +
           "#{Time.zone.today + 1.month}T04:00:00.000Z" + '","venue_name":"奥多摩町","address":"奥多摩町","lat":"35.801763000000","long":"139.087656000000","ticket_limit":30,"published_at":"' +
           "#{Time.zone.today - 4.days}T03:43:04.000Z" + '","updated_at":"' +
           "#{Time.zone.today}T11:31:21.810Z" + '","group":5555,"banner":null,"description":"CoderDojo description","public_url":"https://coderdojo-okutama.doorkeeper.jp/events/8888","participants":12,"waitlisted":0}},' +
       '{"event":{"title":"CoderDojo title","id":2345,"starts_at":"' +
           "#{Time.zone.today + 1.month + 1.day}T01:00:00.000Z" + '","ends_at":"' +
           "#{Time.zone.today + 1.month + 1.day}T04:00:00.000Z" + '","venue_name":"奥多摩町","address":"奥多摩町","lat":"35.801763000000","long":"139.087656000000","ticket_limit":30,"published_at":"' +
           "#{Time.zone.today - 4.days}T03:43:04.000Z" + '","updated_at":"' +
           "#{Time.zone.today}T11:31:21.810Z" + '","group":5555,"banner":null,"description":"CoderDojo description","public_url":"https://coderdojo-okutama.doorkeeper.jp/events/8888","participants":12,"waitlisted":0}}]'
    ]
  end
end
