module Statistics
  class Client
    class_attribute :debug
    self.debug = false

    def initialize(endpoint, &block)
      @conn = connection_for(endpoint, &block)
    end

    def get(path, params)
      @conn.get(path, params).body
    end

    private

    def connection_for(endpoint, &block)
      Faraday.new(endpoint) do |f|
        f.response :logger if self.class.debug
        f.response :json, :content_type => /\bjson$/
        f.response :raise_error

        yield f if block_given?

        f.adapter  Faraday.default_adapter
      end
    end

    class Connpass
      ENDPOINT = 'https://connpass.com/api/v1'.freeze

      def initialize
        @client = Client.new(ENDPOINT)
      end

      def fetch_series_id(**params)
        @client.get('event/', params.merge(count: 1))
          .fetch('events')
          .first
          .dig('series', 'id')
      end

      def fetch_events(series_id:)
        @client.get('event/', series_id: series_id, count: 100)
          .fetch('events')
      end
    end

    class Doorkeeper
      ENDPOINT = 'https://api.doorkeeper.jp'.freeze
      DEFAULT_SINCE = Date.parse('2010-07-01')

      def initialize
        @client = Client.new(ENDPOINT) do |c|
          c.authorization(:Bearer, ENV.fetch('DOORKEEPER_API_TOKEN'))
        end
      end

      def fetch_group_id(keyword:)
        @client.get('events', q: keyword, since: DEFAULT_SINCE)
          .first
          .dig('event', 'group')
      end

      def fetch_events(group_id:, offset: 1, since: DEFAULT_SINCE)
        @client.get("groups/#{group_id}/events", offset: offset, since: since)
      end
    end
  end
end
