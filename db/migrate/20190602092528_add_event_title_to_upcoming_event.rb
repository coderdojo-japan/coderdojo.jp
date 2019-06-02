class AddEventTitleToUpcomingEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :upcoming_events, :event_title, :string, null: false
  end
end
