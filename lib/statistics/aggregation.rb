module Statistics
  class Aggregation
    class << self
      def run(date:)
        cnps_dojos = Dojo.includes(:dojo_event_services).where(dojo_event_services: { name: :connpass }).to_a
        drkp_dojos = Dojo.includes(:dojo_event_services).where(dojo_event_services: { name: :doorkeeper }).to_a
        fsbk_dojos = Dojo.includes(:dojo_event_services).where(dojo_event_services: { name: :facebook }).to_a

        Connpass.run(cnps_dojos, date)
        Doorkeeper.run(drkp_dojos, date)
        Facebook.run(fsbk_dojos, date)
      end
    end

    class Connpass
      class << self
        def run(dojos, date)
          cnps = Client::Connpass.new
          params = {
            yyyymm: "#{date.year}#{date.month}"
          }

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
        def run(dojos, date)
          drkp = Client::Doorkeeper.new
          params = {
            since_at: date.beginning_of_month,
            until_at: date.end_of_month
          }

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
        def run(dojos, date)
          fsbk = Client::Facebook.new
          params = {
            since_at: date.beginning_of_month,
            until_at: date.end_of_month
          }

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
