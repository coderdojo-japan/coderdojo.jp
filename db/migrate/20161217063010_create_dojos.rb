class CreateDojos < ActiveRecord::Migration[4.2]
  def change
    create_table :dojos do |t|
      t.string  :name
      t.string  :email
      t.integer :order, default: 1
      t.string  :description
      t.string  :logo,  default: "/logo.png"
      t.string  :url,   default: "#"
      t.text    :tags

      t.timestamps null: false
    end
  end
end
