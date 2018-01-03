module Statistics
  class Aggregation
    class << self
      def run(date:, weekly:)
        cnps_dojos, drkp_dojos, fsbk_dojos = fetch_dojos

        Connpass.run(cnps_dojos, date, weekly)
        Doorkeeper.run(drkp_dojos, date, weekly)
        Facebook.run(fsbk_dojos, date, weekly)
      end

      def fetch_dojos
        [
          Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: :connpass }).to_a,
          Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: :doorkeeper }).to_a,
          Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: :facebook }).to_a
        ]
      end
    end

    class Connpass
      class << self
        def run(dojos, date, weekly)
          cnps = Providers::Connpass.new
          params = if weekly
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

          dojos.each do |dojo|
            dojo.dojo_event_services.each do |dojo_event_service|
              cnps.fetch_events(params.merge(series_id: dojo_event_service.group_id)).each do |e|
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
      end
    end

    class Doorkeeper
      class << self
        def run(dojos, date, weekly)
          drkp = Providers::Doorkeeper.new
          params = if weekly
                     {
                       since_at: date.beginning_of_week,
                       until_at: date.end_of_week
                     }
                   else
                     {
                       since_at: date.beginning_of_month,
                       until_at: date.end_of_month
                     }
                   end

          dojos.each do |dojo|
            dojo.dojo_event_services.each do |dojo_event_service|
              drkp.fetch_events(params.merge(group_id: dojo_event_service.group_id)).each do |e|
                next unless e['group'].to_s == dojo_event_service.group_id

                EventHistory.create!(dojo_id: dojo.id,
                                     dojo_name: dojo.name,
                                     service_name: dojo_event_service.name,
                                     service_group_id: dojo_event_service.group_id,
                                     event_id: e['id'],
                                     event_url: e['public_url'],
                                     participants: e['participants'],
                                     evented_at: Time.zone.parse(e['starts_at']))
              end
            end
          end
        end
      end
    end

    class Facebook
      class << self
        def run(dojos, date, weekly)
          fsbk = Providers::Facebook.new
          params = if weekly
                     {
                       since_at: date.beginning_of_week,
                       until_at: date.end_of_week
                     }
                   else
                     {
                       since_at: date.beginning_of_month,
                       until_at: date.end_of_month
                     }
                   end

          dojos.each do |dojo|
            dojo.dojo_event_services.each do |dojo_event_service|
              fsbk.fetch_events(params.merge(group_id: dojo_event_service.group_id)).each do |e|
                next unless e.dig('owner', 'id') == dojo_event_service.group_id

                EventHistory.create!(dojo_id: dojo.id,
                                     dojo_name: dojo.name,
                                     service_name: dojo_event_service.name,
                                     service_group_id: dojo_event_service.group_id,
                                     event_id: e['id'],
                                     event_url: "https://www.facebook.com/events/#{e['id']}",
                                     participants: e['attending_count'],
                                     evented_at: Time.zone.parse(e['start_time']))
              end
            end
          end
        end
      end
    end
  end
end
