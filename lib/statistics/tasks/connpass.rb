module Statistics
  module Tasks
    class Connpass
      def self.delete_event_histories(period, dojo_id)
        histories = EventHistory.for(:connpass).within(period)
        histories = histories.where(dojo_id: dojo_id) if dojo_id
        histories.delete_all
      end

      def initialize(dojos, period)
        @client = EventService::Providers::Connpass.new
        @dojos = dojos
        @params = build_params(period)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:connpass).each do |dojo_event_service|
            @client.fetch_events(**@params.merge(series_id: dojo_event_service.group_id)).each do |e|
              next unless e.dig('series', 'id').to_s == dojo_event_service.group_id
        
              EventHistory.create!(dojo_id: dojo.id,
                                   dojo_name: dojo.name,
                                   service_name: dojo_event_service.name,
                                   service_group_id: dojo_event_service.group_id,
                                   event_id: e['event_id'],
                                   event_url: e['event_url'],
                                   participants: e['accepted'],
                                   evented_at: Time.zone.parse(e['started_at']))
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
