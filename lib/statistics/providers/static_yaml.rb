module Statistics
  module Providers
    class StaticYaml
      YAML_FILE = Rails.root.join('db', 'static_event_histories.yaml')

      def fetch_events
        YAML.load_file(YAML_FILE) || []
      end
    end
  end
end
