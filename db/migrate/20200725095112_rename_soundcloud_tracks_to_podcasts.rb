class RenameSoundcloudTracksToPodcasts < ActiveRecord::Migration[5.2]
  def change
    rename_table :soundcloud_tracks, :podcasts
  end
end
