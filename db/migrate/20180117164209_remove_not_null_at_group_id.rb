class RemoveNotNullAtGroupId < ActiveRecord::Migration[5.1]
  def change
    change_column_null :dojo_event_services, :group_id, true
    change_column_null :event_histories, :service_group_id, true
  end
end
