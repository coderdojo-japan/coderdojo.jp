module Statistics
  module Providers
    class Connpass
      ENDPOINT = 'https://connpass.com/api/v1'.freeze

      def initialize
        @client = Statistics::Client.new(ENDPOINT)
      end

      def search(keyword:)
        @client.get('event/', { keyword: keyword, count: 100 })
      end

      def fetch_events(series_id:, yyyymm: nil, yyyymmdd: nil)
        params = {
          series_id: series_id,
          start: 1,
          count: 100
        }
        params[:ym] = yyyymm if yyyymm
        params[:ymd] = yyyymmdd if yyyymmdd
        events = []

        loop do
          part = @client.get('event/', params)

          break if part['results_returned'].zero?

          events.push(*part.fetch('events'))

          break if part.size < params[:count]

          break if params[:start] + params[:count] > part['results_available']

          params[:start] += params[:count]
        end

        events
      end
    end
  end
end
