module Statistics
  module Tasks
    class Connpass
      def initialize(dojos, date, weekly)
        @client = Providers::Connpass.new
        @dojos = dojos
        @params = build_params(date, weekly)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:connpass).each do |dojo_event_service|
            @client.fetch_events(@params.merge(series_id: dojo_event_service.group_id)).each do |e|
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

      def build_params(date, weekly)
        if weekly
          week_days = loop.with_object([date]) { |_, list|
            nd = list.last.next_day
            raise StopIteration if nd > date.end_of_week
            list << nd
          }.map { |date| date.strftime('%Y%m%d') }

          {
            yyyymmdd: week_days.join(',')
          }
        else
          {
            yyyymm: "#{date.year}#{date.month}"
          }
        end
      end
    end
  end
end
