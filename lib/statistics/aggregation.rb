module Statistics
  class Aggregation
    class << self
      def run(date:, weekly:)
        cnps_dojos, drkp_dojos, fsbk_dojos = fetch_dojos

        Tasks::Connpass.run(cnps_dojos, date, weekly)
        Tasks::Doorkeeper.run(drkp_dojos, date, weekly)
        Tasks::Facebook.run(fsbk_dojos, date, weekly)
      end

      def fetch_dojos
        [
          Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: :connpass }).to_a,
          Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: :doorkeeper }).to_a,
          Dojo.eager_load(:dojo_event_services).where(dojo_event_services: { name: :facebook }).to_a
        ]
      end
    end
  end
end
