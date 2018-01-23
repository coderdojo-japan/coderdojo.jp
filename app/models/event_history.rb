class EventHistory < ApplicationRecord
  belongs_to :dojo

  validates :dojo_name, presence: true
  validates :service_name, presence: true, uniqueness: { scope: :event_id  }
  validates :event_id, presence: true
  validates :event_url, presence: true, uniqueness: true, allow_nil: true
  validates :participants, presence: true
  validates :evented_at, presence: true

  scope :for, ->(service) { where(service_name: service) }
  scope :within, ->(period) { where(evented_at: period) }
end
