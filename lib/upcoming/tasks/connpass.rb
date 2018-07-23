module Upcoming
  module Tasks
    class Connpass
      def self.delete_upcoming_event
        UpcomingEvent.for(:connpass).delete_all
      end

      def initialize(dojos, date)
        @client = EventService::Providers::Connpass.new
        @dojos = dojos
        @params = build_params(date)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:connpass).each do |dojo_event_service|
            @client.fetch_events(@params.merge(series_id: dojo_event_service.group_id)).each do |e|
              next unless e.dig('series', 'id').to_s == dojo_event_service.group_id

              UpcomingEvent.create!(dojo_event_service: dojo_event_service,
                                   event_id: e['event_id'],
                                   event_url: e['event_url'],
                                   event_at: Time.zone.parse(e['started_at']))
            end
          end
        end
      end

      private

      def build_params(date)
        { yyyymm: "#{date.year}#{date.month}" }
      end
    end
  end
end
