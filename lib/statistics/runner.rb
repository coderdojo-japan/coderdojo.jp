module Statistics
  class Runner
    class << self
      def run
        cnps_dojos = Dojo.joins(:dojo_event_service).where(dojo_event_service: { name: 'connpass' }).to_a
        drkp_dojos = Dojo.joins(:dojo_event_service).where(dojo_event_service: { name: 'doorkeeper' }).to_a

        Connpass.run(cnps_dojos)
        Doorkeeper.run(drkp_dojos)
      end
    end

    class Connpass
      class << self
        def run(dojos)
          cnps = Cilient::Connpass.new
          dojos.each do |dojo|
            cnps.fetch_events(series_id: dojo.dojo_event_service.group_id).each do |e|
              next unless e.dig('series', 'id') == dojo.dojo_event_service.group_id

              EventHistory.create!(dojo_id: dojo.id,
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
        def run(dojos)
          drkp = Client::Doorkeeper.new
          dojos.each do |dojo|
            drkp.fetch_events(group_id: dojo.dojo_event_service.group_id).each do |e|
              next unless e['group'] == dojo.dojo_event_service.group_id

              EventHistory.create!(dojo_id: dojo.id,
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
