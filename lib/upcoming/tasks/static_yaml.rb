module Upcoming
  module Tasks
    class StaticYaml
      def self.delete_upcoming_event
        UpcomingEvent.for(:static_yaml).delete_all
      end

      def initialize(dojos, _date)
        @client = EventService::Providers::StaticYaml.new
        @dojos = dojos
      end

      def run
        dojos_hash = @dojos.index_by(&:id)
        @client.fetch_events.each do |e|
          dojo = dojos_hash[e['dojo_id'].to_i]
          next unless dojo

          dojo.dojo_event_services.for(:static_yaml).each do |dojo_event_service|
            evented_at = Time.zone.parse(e['evented_at'])
            event_id = "#{SecureRandom.uuid}"

            UpcomingEvent.create!(dojo_event_service: dojo_event_service,
                                  event_id: event_id,
                                  event_url: "https://dummy.url/#{event_id}",
                                  event_at: evented_at)

          end
        end
      end
    end
  end
end
