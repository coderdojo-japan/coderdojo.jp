module Statistics
  module Tasks
    class Facebook
      # MEMO: Duck Typing (COOL!!)
      #       This method is called as general provider in `lib/statistics/aggregation.rb`
      def self.delete_event_histories(period, dojo_id)
        histories = EventHistory.for(:facebook).within(period)
        histories = histories.where(dojo_id: dojo_id) if dojo_id
        histories.delete_all
      end

      def initialize(dojos, period)
        @client = EventService::Providers::Facebook.new
        @dojos = dojos
        @params = build_params(period)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:facebook).each do |dojo_event_service|
            @client.fetch_events(**@params.merge(dojo_id: dojo.id)).each do |e|
              if e['event_id']
                event_id = e['event_id']
                event_url = "https://www.facebook.com/events/#{event_id}"
              else
                event_id = "#{SecureRandom.uuid}"
                event_url = "https://dummy.url/#{event_id}"
              end

              EventHistory.create!(dojo_id: dojo.id,
                                   dojo_name: dojo.name,
                                   service_name: dojo_event_service.name,
                                   service_group_id: dojo_event_service.group_id,
                                   event_id: event_id,
                                   event_url: event_url,
                                   participants: e['participants'],
                                   evented_at: Time.zone.parse(e['evented_at']))
            end
          end
        end
      end

      private

      def build_params(period)
        {
          since_at: period.first.beginning_of_day,
          until_at: period.last.end_of_day
        }
      end
    end
  end
end
