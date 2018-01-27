class DojoEventService < ApplicationRecord
  belongs_to :dojo
  enum name: %i( connpass doorkeeper facebook static_yaml )

  validates :name, presence: true

  scope :for, ->(service) { where(name: service) }
end
