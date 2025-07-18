FactoryBot.define do
  factory :news do
    sequence(:title) { |n| "Test News Article #{n}" }
    sequence(:url) { |n| "https://news.coderdojo.jp/#{n}" }
    published_at { 1.day.ago }
  end
end
