module Upcoming
  module Tasks
    class Doorkeeper
      def self.delete_upcoming_event
        UpcomingEvent.for(:doorkeeper).delete_all
      end

      def initialize(dojos, date)
        @client = EventService::Providers::Doorkeeper.new
        @dojos = dojos
        @params = build_params(date)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:doorkeeper).each do |dojo_event_service|
            @client.fetch_events(@params.merge(group_id: dojo_event_service.group_id)).each do |e|
              next unless e['group'].to_s == dojo_event_service.group_id

              UpcomingEvent.create!(dojo_event_service: dojo_event_service,
                                   event_id: e['id'],
                                   event_url: e['public_url'],
                                   event_at: Time.zone.parse(e['starts_at']))
            end
          end
        end
      end

      private

      def build_params(date)
        {
          since_at: date.beginning_of_month,
          until_at: date.end_of_month
        }
      end
    end
  end
end
