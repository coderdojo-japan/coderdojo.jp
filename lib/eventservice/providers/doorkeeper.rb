module EventService
  module Providers
      class Doorkeeper
        ENDPOINT = 'https://api.doorkeeper.jp'.freeze

        def initialize
          @client = Statistics::Client.new(ENDPOINT) do |c|
            c.authorization(:Bearer, ENV.fetch('DOORKEEPER_API_TOKEN'))
          end
          @default_since = Time.zone.parse('2010-07-01')
          @default_until = Time.zone.now.end_of_day
        end

        def search(keyword:)
          @client.get('events', q: keyword, since: @default_since, expand: 'group')
        end

        def fetch_events(group_id:, since_at: @default_since, until_at: @default_until)
          begin
            params = {
              page: 1,
              since: since_at,
              until: until_at
            }
            events = []

            loop do
              part = @client.get("groups/#{group_id}/events", params)

              break if part.size.zero?

              events.push(*part.map { |e| e['event'] })

              break if part.size < 25   # 25 items / 1 request

              params[:page] += 1
            end

            events
          rescue Faraday::ClientError => e
            raise e unless e.response[:status] == 429

            puts 'API rate limit exceeded.'
            puts "This task will retry in 60 seconds from now(#{Time.zone.now})."
            sleep 60
            retry
          end
        end
      end
  end
end
