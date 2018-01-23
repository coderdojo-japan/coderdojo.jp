class DojoEventService < ApplicationRecord
  belongs_to :dojo
  enum name: %i( connpass doorkeeper facebook )

  scope :for, ->(service) { where(name: service) }
end
