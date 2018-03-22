class UpcomingEvent < ApplicationRecord
  belongs_to :dojo

  validates :dojo_event_service_id, presence: true
  validates :event_id, presence: true
  validates :event_url,presence: true

  validates :event_at,presence: true
end