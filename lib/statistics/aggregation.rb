module Statistics
  class Aggregation
    class << self
      def run(date:)
        cnps_dojos = Dojo.joins(:dojo_event_service).where(dojo_event_services: { name: 'connpass' }).to_a
        drkp_dojos = Dojo.joins(:dojo_event_service).where(dojo_event_services: { name: 'doorkeeper' }).to_a

        Connpass.run(cnps_dojos, date)
        Doorkeeper.run(drkp_dojos, date)
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
            cnps.fetch_events(params.merge(series_id: dojo.dojo_event_service.group_id)).each do |e|
              next unless e.dig('series', 'id') == dojo.dojo_event_service.group_id

              EventHistory.find_or_create_by!(dojo_id: dojo.id,
                                              dojo_name: dojo.name,
                                              service_name: dojo.dojo_event_service.name,
                                              service_group_id: dojo.dojo_event_service.group_id,
                                              event_id: e['event_id'],
                                              event_url: e['event_url'],
                                              participants: e['accepted'],
                                              evented_at: Time.zone.parse(e['started_at']))
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
            drkp.fetch_events(params.merge(group_id: dojo.dojo_event_service.group_id)).each do |e|
              next unless e['group'] == dojo.dojo_event_service.group_id

              EventHistory.find_or_create_by!(dojo_id: dojo.id,
                                              dojo_name: dojo.name,
                                              service_name: dojo.dojo_event_service.name,
                                              service_group_id: dojo.dojo_event_service.group_id,
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
end
