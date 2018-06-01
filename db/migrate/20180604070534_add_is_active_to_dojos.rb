class AddIsActiveToDojos < ActiveRecord::Migration[5.1]
  def change
    add_column :dojos, :is_active, :boolean, null: false, default: true
  end
end
