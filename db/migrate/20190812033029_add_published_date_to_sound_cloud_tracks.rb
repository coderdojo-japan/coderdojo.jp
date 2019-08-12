class AddPublishedDateToSoundCloudTracks < ActiveRecord::Migration[5.1]
  def up
    add_column :soundcloud_tracks, :published_date, :date, null: false, default: -> { "CURRENT_DATE" }

    execute <<-SQL
      UPDATE soundcloud_tracks SET published_date = '2017/03/25' WHERE track_id = 614641407;
      UPDATE soundcloud_tracks SET published_date = '2017/04/13' WHERE track_id = 614642385;
      UPDATE soundcloud_tracks SET published_date = '2017/04/15' WHERE track_id = 614792823;
      UPDATE soundcloud_tracks SET published_date = '2017/04/16' WHERE track_id = 614799783;
      UPDATE soundcloud_tracks SET published_date = '2017/04/22' WHERE track_id = 614981916;
      UPDATE soundcloud_tracks SET published_date = '2017/04/24' WHERE track_id = 614981952;
      UPDATE soundcloud_tracks SET published_date = '2017/04/25' WHERE track_id = 614981976;
      UPDATE soundcloud_tracks SET published_date = '2017/07/07' WHERE track_id = 614982066;
      UPDATE soundcloud_tracks SET published_date = '2017/09/16' WHERE track_id = 614982087;
      UPDATE soundcloud_tracks SET published_date = '2018/12/05' WHERE track_id = 614982105;
      UPDATE soundcloud_tracks SET published_date = '2019/03/25' WHERE track_id = 614982114;
      UPDATE soundcloud_tracks SET published_date = '2019/05/18' WHERE track_id = 625063656;
      UPDATE soundcloud_tracks SET published_date = '2019/05/30' WHERE track_id = 630718164;
      UPDATE soundcloud_tracks SET published_date = '2019/08/13' WHERE track_id = 665969993;
    SQL

    change_column_default :soundcloud_tracks, :published_date, from: -> { "CURRENT_DATE" }, to: nil
  end

  def down
    remove_column :soundcloud_tracks, :published_date, :date
  end
end
