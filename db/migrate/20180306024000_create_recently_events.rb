class CreateRecentlyEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :recently_events do |t|
      t.integer :dojo_id
      t.string :dojo_name
      t.string :service_name
      t.string :service_group_id
      t.string :event_id
      t.string :event_url
      t.datetime :evented_ad
    end
  end
end
