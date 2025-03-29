require 'csv'
csv_data = CSV.generate do |csv|
  csv << %w(開催日 参加数 URL)
  @event_histories.each do |event|
    csv << [event[:evented_at].strftime("%F"), event[:participants], event[:event_url]]
  end
end
