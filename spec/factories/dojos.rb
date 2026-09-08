FactoryBot.define do
  factory :dojo do
    # ID は DB のシーケンスに任せる。開始値は spec/rails_helper.rb で
    # 実在の道場より大きい値に進めている（→ spec/models/dojo_factory_spec.rb）。
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
