module Statistics
  module Tasks
    class StaticYaml
      def self.delete_event_histories(_period)
        EventHistory.for(:static_yaml).delete_all
      end

      def initialize(dojos, _date, _weekly)
        @client = Providers::StaticYaml.new
        @dojos = dojos
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.each do |dojo_event_service|
            @client.fetch_events.each do |e|
              next unless dojo.id == e['dojo_id'].to_i

              evented_at = Time.zone.parse(e['evented_at'])
              event_id = "#{dojo.id}_#{evented_at.to_i}"

              EventHistory.create!(dojo_id: dojo.id,
                                   dojo_name: dojo.name,
                                   service_name: dojo_event_service.name,
                                   event_id: event_id,
                                   event_url: "https://dummy.url/#{event_id}",
                                   participants: e['participants'],
                                   evented_at: evented_at)
            end
          end
        end
      end
    end
  end
end
