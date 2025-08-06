class AddInactivatedAtToDojos < ActiveRecord::Migration[8.0]
  def change
    add_column :dojos, :inactivated_at, :datetime, default: nil
    add_index :dojos, :inactivated_at
  end
end
