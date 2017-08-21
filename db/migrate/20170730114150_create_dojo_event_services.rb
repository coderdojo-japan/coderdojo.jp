class CreateDojoEventServices < ActiveRecord::Migration[5.0]
  def change
    create_table :dojo_event_services do |t|
      t.references :dojo, foreign_key: true, index: true, null: false
      t.string :name
      t.string :url
      t.integer :group_id
      t.timestamps
    end
  end
end
