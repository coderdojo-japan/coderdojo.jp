class AddDetailsToUpcomingEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :upcoming_events, :event_update_at, :datetime
    add_column :upcoming_events, :address, :string
    add_column :upcoming_events, :place, :string
    add_column :upcoming_events, :limit, :integer
  end
end
