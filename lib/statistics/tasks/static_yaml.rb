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
        @dojos  = dojos
      end

      def run
        @client.fetch_events.each do |e|
          this_dojo = Dojo.find(e['dojo_id'])
          event_id  = Time.zone.parse(e['evented_at']).to_i.to_s
          event_url = e['event_url'] || "https://example.com/#{event_id}"
          #pp e['evented_at'] + " | " + EventHistory.count.to_s + " | " + event_url

          EventHistory.create!(
            dojo_id:      this_dojo.id,
            dojo_name:    this_dojo.name,
            service_name: self.class.name.demodulize.underscore,
            event_id:     event_id,
            event_url:    event_url, # MEMO: Required to be UNIQUE.
            participants: e['participants'],
            evented_at:   Time.zone.parse(e['evented_at']),
          )
        end
      end
    end
  end
end
