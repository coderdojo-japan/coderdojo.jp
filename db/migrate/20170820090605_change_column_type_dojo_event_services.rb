class ChangeColumnTypeDojoEventServices < ActiveRecord::Migration[5.0]
  def up
    change_column :dojo_event_services, :name, 'integer USING CAST(name AS integer)', null: false
  end

  def down
    change_column :dojo_event_services, :name, :string, null: false
  end
end
