module Upcoming
  module Tasks
    class Facebook
      def self.delete_upcoming_event
        UpcomingEvent.for(:facebook).delete_all
      end

      def initialize(dojos, date)
        @client = EventService::Providers::Facebook.new
        @dojos = dojos
        @params = build_params(date)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:facebook).each do |dojo_event_service|
            @client.fetch_events(@params.merge(group_id: dojo_event_service.group_id)).each do |e|
              next unless e.dig('owner', 'id') == dojo_event_service.group_id

              UpcomingEvent.create!(dojo_event_service_id: e['id'],
                                   event_id: e['id'],
                                   event_url: "https://www.facebook.com/events/#{e['id']}",
                                   event_at: Time.zone.parse(e['start_time']))
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
