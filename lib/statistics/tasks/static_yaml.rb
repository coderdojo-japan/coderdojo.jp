module Statistics
  module Tasks
    class StaticYaml
      def self.delete_event_histories(_period, dojo_id)
        histories = EventHistory.for(:static_yaml)
        histories = histories.where(dojo_id: dojo_id) if dojo_id
        histories.delete_all
      end

      def initialize(dojos, _date)
        @client = EventService::Providers::StaticYaml.new
        @dojos = dojos
      end

      def run
        dojos_hash = @dojos.index_by(&:id)
        @client.fetch_events.each do |e|
          dojo = dojos_hash[e['dojo_id'].to_i]
          next unless dojo

          event_id = "#{SecureRandom.uuid}"

          EventHistory.create!(dojo_id: dojo.id,
                               dojo_name: dojo.name,
                               service_name: self.class.name.demodulize.underscore,
                               event_id: event_id,
                               event_url: "https://dummy.url/#{event_id}",
                               participants: e['participants'],
                               evented_at: Time.zone.parse(e['evented_at']))
        end
      end
    end
  end
end
