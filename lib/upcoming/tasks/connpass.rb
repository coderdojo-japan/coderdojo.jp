module Upcoming
  module Tasks
    class Connpass
      def self.delete_event_histories(period)
        EventHistory.for(:connpass).within(period).delete_all
      end

      def initialize(dojos, date, weekly)
        @client = EventService::Providers::Connpass.new
        @dojos = dojos
        @params = build_params(date, weekly)
      end

      def run
        @dojos.each do |dojo|
          dojo.dojo_event_services.for(:connpass).each do |dojo_event_service|
            @client.fetch_events(@params.merge(series_id: dojo_event_service.group_id)).each do |e|
              next unless e.dig('series', 'id').to_s == dojo_event_service.group_id

              UpcomingEvent.create!(dojo_event_service_id: e['id'],
                                   event_id: e['event_id'],
                                   event_url: e['event_url'],
                                   event_at: Time.zone.parse(e['started_at']))
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
