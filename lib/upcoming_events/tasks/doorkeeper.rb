module UpcomingEvents
  module Tasks
    class Doorkeeper
      def initialize(dojos, period)
        @client = EventService::Providers::Doorkeeper.new
        @dojos  = dojos
        @params = build_params(period)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:doorkeeper).each do |dojo_event_service|
            events = @client.fetch_events(**@params.merge(group_id: dojo_event_service.group_id))
            puts "[doorkeeper] dojo_id: #{dojo.id}, group_id: #{dojo_event_service.group_id}, fetched events: #{events&.size || 0}"
            (events || []).compact.each do |e|
              puts "[doorkeeper] event_id: #{e.fetch('id')}, title: #{e.fetch('title')}"
              next unless e.fetch('group').to_s == dojo_event_service.group_id

              record = dojo_event_service.upcoming_events.find_or_initialize_by(event_id: e.fetch('id'))
              record.update!(service_name: dojo_event_service.name,
                             event_title:  e.fetch('title'),
                             event_url:    e.fetch('public_url'),
                             participants: e.fetch('participants'),
                             event_at:     Time.zone.parse(e.fetch('starts_at')),
                             event_end_at: Time.zone.parse(e.fetch('ends_at')),
                             event_update_at: Time.zone.parse(e.fetch('updated_at')),
                             address:      e.fetch('address'),
                             place:        e.fetch('venue_name'),
                             limit:        e.fetch('ticket_limit'))
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
