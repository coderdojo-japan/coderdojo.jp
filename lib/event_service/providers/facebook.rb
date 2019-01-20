module EventService
  module Providers
      class Facebook
        class_attribute :access_token
        # NOTE: 指定は since, untill パラメータ指定、未指定時直近二週間

        def initialize
          @client = Koala::Facebook::API.new(self.access_token)
        end

        # NOTE: since_at, until_at は DateTime で指定
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
