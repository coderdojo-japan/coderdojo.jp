RSpec.shared_context 'Use stub connection of Faraday' do
  let(:stub_connection) do
    Faraday.new do |f|
      f.response :json, :content_type => /\bjson$/
      f.adapter :test, Faraday::Adapter::Test::Stubs.new do |stub|
        # connpass
        stub.get('/events/') do |env|
          puts "[DEBUG] Request path: #{env.url.path}"
          puts "[DEBUG] Request params: #{env.params.inspect}"
          group_id = env.params["group_id"]
          group_id = group_id.join(',') if group_id.is_a?(Array)
          group_id = group_id.to_s if group_id.is_a?(Integer)
          puts "[DEBUG] group_id: #{group_id.inspect}"
          response_json =
            if group_id == '9876,9877'
              multiple_series_ids_response[2]
            elsif group_id == '9876'
              connpass_response[2]
            else
              connpass_response[2]
            end
          ConnpassApiV2::Response.new(JSON.parse(response_json))
        end

        # doorkeeper
        stub.get('/events') { doorkeeper_response }
        stub.get('/groups/5555/events') { doorkeeper_response }
      end
    end
  end

  before do
    allow_any_instance_of(EventService::Client).to receive(:connection_for).and_return(stub_connection)
    allow_any_instance_of(ConnpassApiV2::Client).to receive(:get_events) do |instance, **args|
      if args[:group_id] == '9876,9877'
        ConnpassApiV2::Response.new(JSON.parse(multiple_series_ids_response[2]))
      elsif args[:group_id] == '9876'
        ConnpassApiV2::Response.new(JSON.parse(connpass_response[2]))
      else
        ConnpassApiV2::Response.new(JSON.parse(connpass_response[2]))
      end
    end
  end
end

RSpec.shared_context 'Use stubs for Connpass' do
  include_context 'Use stub connection of Faraday'

  # response for multiple series_ids 9876 and 9877
  let(:multiple_series_ids_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '{"results_returned": 5, "events": [
        {"url": "https://coderdojo-okutama.connpass.com/event/12345/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama.connpass.com/", "id": 9876, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12345, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12346/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12346, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12347/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12347, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12348/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12348, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12349/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12349, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"}
      ], "results_start": 200, "results_available": 518}'
    ]
  end

  # response for single series_id 9876, and for search
  let(:connpass_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      '{"results_returned": 100, "events": [
        {"url": "https://coderdojo-okutama.connpass.com/event/12345/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama.connpass.com/", "id": 9876, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12345, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12346/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12346, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12347/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12347, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12348/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "2017-04-29T14:59:30+09:00", "lat": "35.801763000000", "started_at": "2017-05-07T10:00:00+09:00", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12348, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "2017-05-07T12:00:00+09:00", "place": "Tokyo"}
      ], "results_start": 200, "results_available": 518}'
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
      '{"results_returned": 5, "events": [
        {"url": "https://coderdojo-okutama.connpass.com/event/12345/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama.connpass.com/", "id": 9876, "title": "CoderDojo series"}, "updated_at": "' +
        "#{Time.zone.today}T14:59:30+09:00" + '", "lat": "35.801763000000", "started_at": "' +
        "#{Time.zone.today + 1.month}T13:00:00+09:00" + '", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12345, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "' +
        "#{Time.zone.today + 1.month}T15:00:00+09:00" + '", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12346/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "' +
        "#{Time.zone.today}T14:59:30+09:00" + '", "lat": "35.801763000000", "started_at": "' +
        "#{Time.zone.today + 1.month}T13:00:00+09:00" + '", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12346, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "' +
        "#{Time.zone.today + 1.month}T15:00:00+09:00" + '", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12347/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "' +
        "#{Time.zone.today}T14:59:30+09:00" + '", "lat": "35.801763000000", "started_at": "' +
        "#{Time.zone.today + 1.month}T13:00:00+09:00" + '", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12347, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "' +
        "#{Time.zone.today + 1.month}T15:00:00+09:00" + '", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12348/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "' +
        "#{Time.zone.today}T14:59:30+09:00" + '", "lat": "35.801763000000", "started_at": "' +
        "#{Time.zone.today + 1.month}T13:00:00+09:00" + '", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12348, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "' +
        "#{Time.zone.today + 1.month}T15:00:00+09:00" + '", "place": "Tokyo"},
        {"url": "https://coderdojo-okutama.connpass.com/event/12349/", "event_type": "participation", "owner_nickname": "nalabjp", "group": {"url": "https://coderdojo-okutama2.connpass.com/", "id": 9877, "title": "CoderDojo series"}, "updated_at": "' +
        "#{Time.zone.today}T14:59:30+09:00" + '", "lat": "35.801763000000", "started_at": "' +
        "#{Time.zone.today + 1.month}T13:00:00+09:00" + '", "hash_tag": "CoderDojo", "title": "CoderDojo title", "id": 12349, "lon": "139.087656000000", "waiting": 2, "limit": 10, "owner_id": 2525, "owner_display_name": "nalabjp", "description": "CoderDojo description", "address": "Okutama-cho Tokyo", "catch": "CoderDojo catch", "accepted": 10, "ended_at": "' +
        "#{Time.zone.today + 1.month}T15:00:00+09:00" + '", "place": "Tokyo"}
      ], "results_start": 200, "results_available": 518}'
    ]
  end
end

RSpec.shared_context 'Use stubs UpcomingEvents for Doorkeeper' do
  include_context 'Use stub connection of Faraday'

  let(:doorkeeper_response) do
    [
      200,
      { 'Content-Type' => 'application/json' },
      [
        {
          event: {
            title: "CoderDojo title",
            id: 1234,
            starts_at: "#{Time.zone.today + 1.month}T01:00:00.000Z",
            ends_at: "#{Time.zone.today + 1.month}T04:00:00.000Z",
            venue_name: "奥多摩町",
            address: "奥多摩町",
            lat: "35.801763000000",
            long: "139.087656000000",
            ticket_limit: 30,
            published_at: "#{Time.zone.today - 4.days}T03:43:04.000Z",
            updated_at: "#{Time.zone.today}T11:31:21.810Z",
            group: 5555,
            banner: nil,
            description: "CoderDojo description",
            public_url: "https://coderdojo-okutama.doorkeeper.jp/events/8888",
            participants: 12,
            waitlisted: 0
          }
        },
        {
          event: {
            title: "CoderDojo title",
            id: 2345,
            starts_at: "#{Time.zone.today + 1.month + 1.day}T01:00:00.000Z",
            ends_at: "#{Time.zone.today + 1.month + 1.day}T04:00:00.000Z",
            venue_name: "奥多摩町",
            address: "奥多摩町",
            lat: "35.801763000000",
            long: "139.087656000000",
            ticket_limit: 30,
            published_at: "#{Time.zone.today - 4.days}T03:43:04.000Z",
            updated_at: "#{Time.zone.today}T11:31:21.810Z",
            group: 5555,
            banner: nil,
            description: "CoderDojo description",
            public_url: "https://coderdojo-okutama.doorkeeper.jp/events/8888",
            participants: 12,
            waitlisted: 0
          }
        }
      ]
    ]
  end
end
