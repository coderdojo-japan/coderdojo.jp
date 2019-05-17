class CreateSoundCloudTracks < ActiveRecord::Migration[5.1]
  def change
    create_table :soundcloud_tracks do |t|
      t.integer  :track_id,              null: false
      t.string   :title,                 null: false
      t.text     :description
      t.integer  :original_content_size, null: false
      t.string   :duration,              null: false
      t.string   :tag_list
      t.string   :download_url,          null: false
      t.string   :permalink,             null: false
      t.string   :permalink_url,         null: false
      t.datetime :uploaded_at,           null: false

      t.timestamps null: false
    end
    add_index :soundcloud_tracks, :track_id, unique: true
  end
end
