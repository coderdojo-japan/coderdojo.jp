class ModColumnsToUpcomingEvent < ActiveRecord::Migration[5.1]
  def up
    remove_index :upcoming_events, :dojo_event_service_id
    remove_index :upcoming_events, :event_at
    remove_column :upcoming_events, :dojo_event_service_id

    add_reference :upcoming_events, :dojo, foreign_key: true, index: true, null: false
    add_column :upcoming_events, :dojo_name, :string, null: false
    add_column :upcoming_events, :service_name, :string, null: false
    add_column :upcoming_events, :participants, :integer, null: false
  end

  def down
    remove_reference :upcoming_events, :dojo, findex: true
    remove_column :upcoming_events, :dojo_name, :string, null: false
    remove_column :upcoming_events, :service_name, :string, null: false
    remove_column :upcoming_events, :participants, :integer, null: false

    add_column :upcoming_events, :dojo_event_service_id, :integer, null: false, default: 1
    add_index :upcoming_events, :dojo_event_service_id, name: "index_upcoming_events_on_dojo_event_service_id"
    add_index :upcoming_events, :event_at, name: "index_upcoming_events_on_event_at"
  end
end
