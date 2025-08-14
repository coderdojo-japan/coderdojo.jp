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
    order         { 131001 }
    # デフォルトはアクティブ（inactivated_at: nil）
    inactivated_at { nil }
    
    # 非アクティブなDojoを作成するためのtrait
    trait :inactive do
      inactivated_at { Time.current }
    end
  end
end
