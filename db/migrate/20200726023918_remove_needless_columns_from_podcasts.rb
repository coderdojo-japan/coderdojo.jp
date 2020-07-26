class RemoveNeedlessColumnsFromPodcasts < ActiveRecord::Migration[5.2]
  def change
    remove_column :podcasts, :tag_list,     :string
    remove_column :podcasts, :download_url, :string
    remove_column :podcasts, :uploaded_at,  :datetime
  end
end
