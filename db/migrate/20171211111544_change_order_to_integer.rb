class ChangeOrderToInteger < ActiveRecord::Migration[5.1]

  def up
    change_column :dojos, :order, :string,  default: '000000'
  end

  if connection.adapter_name == 'PostgreSQL'
    def up
      change_column :dojos, :order, 'integer USING CAST(order AS integer)', default: 1
    end
  else
    def down
      change_column :dojos, :order, :integer, default: 1
    end
  end
end

