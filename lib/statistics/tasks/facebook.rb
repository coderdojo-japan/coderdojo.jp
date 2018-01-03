module Statistics
  module Tasks
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
