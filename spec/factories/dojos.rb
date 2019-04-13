FactoryBot.define do
  factory :dojo do
    name          { 'dojo name' }
    email         { '' }
    description   { 'description' }
    prefecture_id { 13 }
  end
end
