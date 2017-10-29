class IntegerToStringOnGroupIdInDojoEventServices < ActiveRecord::Migration[5.0]
  def up
    change_column :dojo_event_services, :group_id, :string, null: false
  end

  def down
    change_column :dojo_event_services, :group_id, :integer, null: false
  end
end
