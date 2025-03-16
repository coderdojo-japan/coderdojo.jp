class CreateStretch3s < ActiveRecord::Migration[7.0]
  def change
    create_table :stretch3s do |t|
      t.string :email, null: false
      t.string :parent_name, null: false
      t.string :participant_name, null: false
      t.string :dojo_name, null: false

      t.timestamps
    end
  end
end
