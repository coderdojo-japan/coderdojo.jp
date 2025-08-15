module EventService
  module Providers
    class Facebook
      # This does NOT call Facebook API but loading static event data.
      # (Same algorithm as 'static_yaml' but data structure seems Facebook compatible?)
      # You can load data from the following YAML file by exec (on Zsh):
      #
      # $ bundle exec rails statistics:aggregation\[-,-,facebook\]
      YAML_FILE = Rails.root.join('db', 'facebook_event_histories.yml')

      def fetch_events(dojo_id: nil, since_at: nil, until_at: nil)
        dojo_ids = dojo_id if dojo_id.is_a?(Array)
        dojo_ids ||= [dojo_id] if dojo_id

        events = YAML.load_file(YAML_FILE) || []
        return events if dojo_ids.blank? && since_at.nil? && until_at.nil?

        results = []
        events.group_by { |d| d['dojo_id'] }.each do |dojo_id, values|
          next if dojo_ids.present? && !dojo_ids.include?(dojo_id)
          if since_at.nil? && until_at.nil?
            results += values
            next
          end
          term = if since_at && until_at
                   (since_at..until_at)
                 elsif since_at
                   (since_at..)
                 else
                   ('2000/01/01 00:00'.in_time_zone..until_at)
                 end
          values.each do |v|
            results << v if term.cover?(v['evented_at'].in_time_zone)
          end
        end
        results
      end
    end
  end
end
