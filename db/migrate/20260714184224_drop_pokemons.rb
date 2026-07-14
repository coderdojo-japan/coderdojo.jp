class DropPokemons < ActiveRecord::Migration[8.0]
  # ポケモン素材のダウンロード機能は、オンライン版への移行（2024年度）に伴い停止済み。
  # 関連するコードを削除したため、未使用となったテーブルを削除する。
  def up
    drop_table :pokemons
  end

  def down
    create_table :pokemons do |t|
      t.string   :email,            null: false
      t.string   :parent_name,      null: false
      t.string   :participant_name, null: false
      t.string   :dojo_name,        null: false
      t.text     :presigned_url
      t.string   :download_key
      t.datetime :created_at,       null: false
      t.datetime :updated_at,       null: false
    end
    add_index :pokemons, :download_key, unique: true
  end
end
