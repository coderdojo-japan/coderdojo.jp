class RenameOriginalContentSizeColumnToPodcasts < ActiveRecord::Migration[5.2]
  def change
    rename_column :podcasts, :original_content_size, :content_size
  end
end
