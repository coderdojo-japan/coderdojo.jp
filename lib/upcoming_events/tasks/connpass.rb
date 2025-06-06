module UpcomingEvents
  module Tasks
    class Connpass
      def initialize(dojos, period)
        @client = EventService::Providers::Connpass.new
        @dojos  = dojos
        @params = build_params(period)
      end

      def run
        group_ids = @dojos.flat_map do |dojo|
          dojo.dojo_event_services.for(:connpass).pluck(:group_id)
        end
      
        @client.fetch_events(**@params.merge(group_id: group_ids)).each do |e|
          dojo_event_service = DojoEventService.find_by(group_id: e.dig('series', 'id').to_s)
          next unless dojo_event_service
      
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
