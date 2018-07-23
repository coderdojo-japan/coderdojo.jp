class UpcomingEvent < ApplicationRecord
  belongs_to :dojo
  belongs_to :dojo_event_service

  validates :dojo_event_service_id, presence: true
  validates :event_id, presence: true
  validates :event_url,presence: true

  validates :event_at,presence: true

  scope :for, ->(service) { UpcomingEvent.where(dojo_event_service: DojoEventService.for(service)) }
end