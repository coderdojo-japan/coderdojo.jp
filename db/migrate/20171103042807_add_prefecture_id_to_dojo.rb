class AddPrefectureIdToDojo < ActiveRecord::Migration[5.1]
  def change
    add_column :dojos, :prefecture_id, :integer
  end
end
