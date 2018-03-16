class CreateUpcomingEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :upcoming_events do |t|
      t.integer :dojo_event_service_id, null: false
      t.string :event_id , null: false
      t.string :event_url, null: false
      t.datetime :event_at , null: false

      t.index :dojo_event_service_id, name: "index_upcoming_events_on_dojo_event_service_id"
      t.index :event_at, name: "index_upcoming_events_on_event_at"
    end
  end
end
