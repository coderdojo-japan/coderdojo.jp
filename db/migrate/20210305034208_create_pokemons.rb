class CreatePokemons < ActiveRecord::Migration[5.2]
  def change
    create_table :pokemons do |t|
      t.string :email,            null: false
      t.string :parent_name,      null: false
      t.string :participant_name, null: false
      t.string :dojo_name,        null: false
      t.text   :presigned_url
      t.string :download_key,     index: { unique: true }

      t.timestamps
    end
  end
end
