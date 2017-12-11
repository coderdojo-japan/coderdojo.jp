class ChangeOrderToInteger < ActiveRecord::Migration[5.1]
  def change
    change_column :dojos, :order, :string,  default: '000000'
  end
end

