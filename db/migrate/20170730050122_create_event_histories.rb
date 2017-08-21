class CreateEventHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :event_histories do |t|
      t.references :dojo, foreign_key: true, index: true, null: false
      t.string :dojo_name, null: false
      t.string :service_name, null: false
      t.integer :service_group_id, null: false
      t.integer :event_id, null: false
      t.string :event_url, unique: true, null: false
      t.integer :participants, null: false
      t.datetime :evented_at, null: false
      t.timestamps

      t.index [:service_name, :event_id], unique: true
      t.index [:evented_at, :dojo_id]
    end
  end
end
