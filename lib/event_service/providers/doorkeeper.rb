module EventService
  module Providers
      class Doorkeeper
        ENDPOINT = 'https://api.doorkeeper.jp'.freeze
        # NOTE: 指定は since, untill パラメータ指定、未指定時本日以降が対象

        def initialize
          @client = EventService::Client.new(ENDPOINT) do |c|
            c.request :authorization, 'Bearer', ENV.fetch('DOORKEEPER_API_TOKEN')
          end
          @default_since = '2010-07-01'.to_date.beginning_of_day
          @default_until = Time.zone.yesterday.end_of_day
        end

        def search(keyword:)
          @client.get('events', q: keyword, since: @default_since, expand: 'group')
        end

        # NOTE: since_at, until_at は DateTime で指定
        def fetch_events(group_id:, since_at: @default_since, until_at: @default_until)
          begin
            params = {
              page: 1,
              since: since_at.utc.iso8601,
              until: until_at.utc.iso8601
            }
            events = []

            loop do
              part = @client.get("groups/#{group_id}/events", params)

              break if part.size.zero?

              events.push(*part.map { |e| e[:event] })

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
