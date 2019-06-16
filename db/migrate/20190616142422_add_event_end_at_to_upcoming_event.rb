class AddEventEndAtToUpcomingEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :upcoming_events, :event_end_at, :datetime, null: false
  end
end
