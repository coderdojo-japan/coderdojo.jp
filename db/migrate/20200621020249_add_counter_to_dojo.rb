class AddCounterToDojo < ActiveRecord::Migration[5.2]
  def change
    add_column :dojos, :counter, :integer, null: false, default: 1
  end
end
