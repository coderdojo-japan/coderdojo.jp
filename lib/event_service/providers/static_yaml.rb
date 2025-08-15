module EventService
  module Providers
    class StaticYaml
      YAML_FILE = Rails.root.join('db', 'static_event_histories.yml')

      def fetch_events
        YAML.load_file(YAML_FILE) || []
      end
    end
  end
end
