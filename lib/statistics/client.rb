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

    def connection_for(endpoint)
      Faraday.new(endpoint) do |f|
        f.response :logger if self.class.debug
        f.response :json, :content_type => /\bjson$/
        f.response :raise_error

        yield f if block_given?

        f.adapter  Faraday.default_adapter
      end
    end

    class Doorkeeper
      ENDPOINT = 'https://api.doorkeeper.jp'.freeze

      def initialize
        @client = Client.new(ENDPOINT) do |c|
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

    class Facebook
      class_attribute :access_token

      def initialize
        @client = Koala::Facebook::API.new(self.access_token)
      end

      def fetch_events(group_id:, since_at: nil, until_at: nil)
        params = {
          fields: %i(attending_count start_time owner),
          limit: 100
        }.tap do |h|
          # @note FacebookのGraph APIはPDTがタイムゾーンとなっており、
          #       JST<->PDTのオフセット8時間を追加した時刻をパラメータとする必要がある
          # @see https://github.com/coderdojo-japan/coderdojo.jp/pull/182#discussion_r148935458
          h[:since] = since_at.since(8.hours).to_i if since_at
          h[:until] = until_at.since(8.hours).to_i if until_at
        end

        events = []

        collection = @client.get_object("#{group_id}/events", params)
        events.push(*collection.to_a)
        while !collection.empty? && collection.paging['next'] do
          events.push(*collection.next_page.to_a)
        end

        events
      end
    end
  end
end
