class DojoEventService < ApplicationRecord
  belongs_to :dojo
  enum name: %i( connpass doorkeeper )
end
