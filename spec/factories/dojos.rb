FactoryBot.define do
  factory :dojo do
    name          { 'dojo name' }
    email         { '' }
    description   { 'description' }
    prefecture_id { 13 }
    tags          { ['Scratch'] }
    url           { 'https://example.com' }
    logo          { '/img/dojos/default.webp' }
    counter       { 1 }
    is_active     { true }
    order         { 131001 }
  end
end
