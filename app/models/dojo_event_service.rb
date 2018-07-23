class DojoEventService < ApplicationRecord
  EXTERNAL_SERVICES = %i( connpass doorkeeper facebook )
  INTERNAL_SERVICES = %i( static_yaml )

  has_many :upcoming_events

  belongs_to :dojo
  enum name: EXTERNAL_SERVICES + INTERNAL_SERVICES

  validates :name, presence: true

  scope :for, ->(service) { where(name: service) }
end
