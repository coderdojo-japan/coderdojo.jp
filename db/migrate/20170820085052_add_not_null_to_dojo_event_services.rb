class AddNotNullToDojoEventServices < ActiveRecord::Migration[5.0]
  def change
    change_column_null :dojo_event_services, :name, false
    change_column_null :dojo_event_services, :group_id, false
  end
end
