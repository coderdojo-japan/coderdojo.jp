class CreatePrefectures < ActiveRecord::Migration[5.1]
  def change
    create_table :prefectures do |t|
      t.string :name
      t.string :region

      t.index :name, unique: true
      t.index :region
    end
  end
end
