class ChangeTrackIdToEnclosureUrl < ActiveRecord::Migration[5.2]
  def change
    rename_column :podcasts, :track_id, :enclosure_url
    change_column :podcasts, :enclosure_url, :string
  end
end
