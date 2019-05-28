class UpcomingEvent < ApplicationRecord
  belongs_to :dojo_event_service

  validates :dojo_name,    presence: true
  validates :service_name, presence: true, uniqueness: { scope: :event_id  }
  validates :event_id,     presence: true
  validates :event_url,    presence: true
  validates :event_at,     presence: true
  validates :participants, presence: true

  scope :for, ->(service) { where(dojo_event_service: DojoEventService.for(service)) }
  scope :until, ->(date) { where('event_at < ?', date.beginning_of_day) }
end
