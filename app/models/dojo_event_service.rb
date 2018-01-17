class DojoEventService < ApplicationRecord
  belongs_to :dojo
  enum name: %i( connpass doorkeeper facebook static_yaml )
end
