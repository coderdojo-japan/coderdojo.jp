class CreateNews < ActiveRecord::Migration[8.0]
  def change
    create_table :news do |t|
      t.string   :title
      t.string   :url
      t.datetime :published_at

      t.timestamps
    end

    add_index :news, :url, unique: true
  end
end
