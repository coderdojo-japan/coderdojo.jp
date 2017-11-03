class ChangeColumnTypeDojoEventServices < ActiveRecord::Migration[5.0]
  if connection.adapter_name == 'PostgreSQL'
    def up
      change_column :dojo_event_services, :name, 'integer USING CAST(name AS integer)', null: false
    end
  else
    def up
      change_column :dojo_event_services, :name, :integer, null: false
    end
  end

  def down
    change_column :dojo_event_services, :name, :string, null: false
  end
end
