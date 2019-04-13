class AddPrivateToDojos < ActiveRecord::Migration[5.1]
  def change
    add_column :dojos, :is_private, :boolean, null: false, default: false
  end
end
