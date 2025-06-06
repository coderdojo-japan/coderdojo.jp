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

        events = @client.fetch_events(**@params.merge(group_id: group_ids))
        puts "[connpass] Fetched events: #{events.size}"
        events.each do |e|
          puts "[connpass] event_id: #{e.fetch('id')}, title: #{e.fetch('title')}"
          dojo_event_service = DojoEventService.find_by(group_id: e.dig('group', 'id').to_s)
          next unless dojo_event_service

          record = dojo_event_service.upcoming_events.find_or_initialize_by(event_id: e.fetch('id'))
          record.update!(service_name: dojo_event_service.name,
                         event_title:  e.fetch('title'),
                         event_url:    e.fetch('url'),
                         event_at:     Time.zone.parse(e.fetch('started_at')),
                         event_end_at: Time.zone.parse(e.fetch('ended_at')),
                         participants: e.fetch('accepted'),
                         event_update_at: Time.zone.parse(e.fetch('updated_at')),
                         address:      e.fetch('address'),
                         place:        e.fetch('place'),
                         limit:        e.fetch('limit'))
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
