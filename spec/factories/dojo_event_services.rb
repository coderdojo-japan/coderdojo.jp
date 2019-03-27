require 'factory_bot'

FactoryBot.define do
  factory :dojo_event_service do
    # dojo_id
    name     { :connpass }
    url      { '' }
    group_id { '9999' }
  end
end
