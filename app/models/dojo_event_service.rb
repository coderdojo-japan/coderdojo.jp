class DojoEventService < ApplicationRecord
  EXTERNAL_SERVICES = %i( connpass doorkeeper facebook )
  INTERNAL_SERVICES = %i( static_yaml )

  belongs_to :dojo
  has_many :upcoming_events, dependent: :destroy

  enum :name, EXTERNAL_SERVICES + INTERNAL_SERVICES

  validates :name, presence: true
  validates :group_id, uniqueness: { scope: :name }, unless: Proc.new { |a| a.group_id.blank? }

  scope :for, ->(service) { where(name: service) }
end
