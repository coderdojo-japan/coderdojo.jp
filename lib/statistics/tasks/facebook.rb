module Statistics
  module Tasks
    class Facebook
      def self.delete_event_histories(period)
        EventHistory.for(:facebook).within(period).delete_all
      end

      def initialize(dojos, period)
        @client = EventService::Providers::Facebook.new
        @dojos = dojos
        @params = build_params(period)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:facebook).each do |dojo_event_service|
            @client.fetch_events(@params.merge(group_id: dojo_event_service.group_id)).each do |e|
              next unless e.dig('owner', 'id') == dojo_event_service.group_id
        
              EventHistory.create!(dojo_id: dojo.id,
                                   dojo_name: dojo.name,
                                   service_name: dojo_event_service.name,
                                   service_group_id: dojo_event_service.group_id,
                                   event_id: e['id'],
                                   event_url: "https://www.facebook.com/events/#{e['id']}",
                                   participants: e['attending_count'],
                                   evented_at: Time.zone.parse(e['start_time']))
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
