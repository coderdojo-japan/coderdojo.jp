class CreateRecentlyEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :recently_events do |t|
      t.integer :dojo_id, null: false
      t.string :dojo_name, null: false
      t.string :service_name, null: false
      t.string :service_group_id
      t.string :event_id, null: false
      t.string :event_url, null: false
      t.datetime :event_at, null: false

      t.index ["dojo_id"], name: "index_recently_events_on_dojo_id"
      t.index ["event_at"], name: "index_recently_events_on_event_at"
      t.index ["event_at", "dojo_id"], name: "index_recently_events_on_event_at_and_dojo_id"
    end
  end
end
