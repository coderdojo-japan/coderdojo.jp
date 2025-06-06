module Statistics
  module Tasks
    class Connpass
      # MEMO: Duck Typing (COOL!!)
      #       This method is called as general provider in `lib/statistics/aggregation.rb`
      def self.delete_event_histories(period, dojo_id)
        histories = EventHistory.for(:connpass).within(period)
        histories = histories.where(dojo_id: dojo_id) if dojo_id
        histories.delete_all
      end

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

          EventHistory.create!(dojo_id:          dojo_event_service.dojo_id,
                               dojo_name:        dojo_event_service.dojo.name,
                               service_name:     dojo_event_service.name,
                               service_group_id: dojo_event_service.group_id,
                               event_id:         e.fetch('id'),
                               event_url:        e.fetch('event_url'),
                               participants:     e.fetch('accepted'),
                               evented_at:       Time.zone.parse(e.fetch('started_at'))
            )
        end
      end

      private

      def build_params(period)
        yyyymmdd = []
        yyyymm   = []

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
          yyyymm:   yyyymm
        }
      end
    end
  end
end
