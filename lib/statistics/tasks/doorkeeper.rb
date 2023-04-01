module Statistics
  module Tasks
    class Doorkeeper
      def self.delete_event_histories(period, dojo_id)
        histories = EventHistory.for(:doorkeeper).within(period)
        histories = histories.where(dojo_id: dojo_id) if dojo_id
        histories.delete_all
      end

      def initialize(dojos, period)
        @client = EventService::Providers::Doorkeeper.new
        @dojos = dojos
        @params = build_params(period)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:doorkeeper).each do |dojo_event_service|
            @client.fetch_events(**@params.merge(group_id: dojo_event_service.group_id)).each do |e|
              next unless e['group'].to_s == dojo_event_service.group_id
        
              EventHistory.create!(dojo_id: dojo.id,
                                   dojo_name: dojo.name,
                                   service_name: dojo_event_service.name,
                                   service_group_id: dojo_event_service.group_id,
                                   event_id: e['id'],
                                   event_url: e['public_url'],
                                   participants: e['participants'],
                                   evented_at: Time.zone.parse(e['starts_at']))
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
