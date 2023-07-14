module UpcomingEvents
  module Tasks
    class Connpass
      def initialize(dojos, period)
        @client = EventService::Providers::Connpass.new
        @dojos  = dojos
        @params = build_params(period)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:connpass).each do |dojo_event_service|
            @client.fetch_events(**@params.merge(series_id: dojo_event_service.group_id)).each do |e|
              next unless e.dig('series', 'id').to_s == dojo_event_service.group_id

              record = dojo_event_service.upcoming_events.find_or_initialize_by(event_id: e['event_id'])
              record.update!(service_name: dojo_event_service.name,
                             event_title:  e['title'],
                             event_url:    e['event_url'],
                             event_at:     Time.zone.parse(e['started_at']),
                             event_end_at: Time.zone.parse(e['ended_at']),
                             participants: e['accepted'],
                             event_update_at: Time.zone.parse(e['updated_at']),
                             address:      e['address'],
                             place:        e['place'],
                             limit:        e['limit'])
            end
          end
        end
      end

      private

      def build_params(period)
        yyyymmdd = []
        yyyymm = []

        st_date = period.first
        ed_date = period.last

        date = period.first
        while date <= ed_date
          if date.day == 1 && date.end_of_month <= ed_date
            yyyymm << date.strftime('%Y%m')
            date += 1.month
          else
            yyyymmdd << date.strftime('%Y%m%d')
            date += 1.day
          end
        end

        {
          yyyymmdd: yyyymmdd,
          yyyymm: yyyymm
        }
      end
    end
  end
end
