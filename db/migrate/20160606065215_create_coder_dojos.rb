class CreateCoderDojos < ActiveRecord::Migration
  def change
    create_table :coder_dojos do |t|
      t.string :name
      t.string :course
      t.string :caption
      t.string :venue
      t.integer :region
      t.string :logo_image_url
      t.string :redirect_url
      t.string :user_name
      t.string :email

      t.timestamps null: false
    end
  end
end
