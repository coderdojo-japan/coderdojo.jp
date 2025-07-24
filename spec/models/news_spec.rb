require 'rails_helper'

RSpec.describe News, type: :model do
  describe 'バリデーション' do
    let(:news) { build(:news) }

    it '有効なファクトリーを持つ' do
      expect(news).to be_valid
    end

    describe 'title' do
      it 'presence: true' do
        news.title = nil
        expect(news).not_to be_valid
        expect(news.errors[:title]).not_to be_empty
      end
    end

    describe 'url' do
      it 'presence: true' do
        news.url = nil
        expect(news).not_to be_valid
        expect(news.errors[:url]).not_to be_empty
      end

      it 'uniqueness: true' do
        create(:news, url: 'https://example.com/test')
        duplicate_news = build(:news, url: 'https://example.com/test')
        expect(duplicate_news).not_to be_valid
        expect(duplicate_news.errors[:url]).not_to be_empty
      end

      it 'URL形式であること' do
        news.url = 'invalid-url'
        expect(news).not_to be_valid
        expect(news.errors[:url]).not_to be_empty
      end

      it 'HTTPSとHTTPを許可する' do
        news.url = 'https://example.com'
        expect(news).to be_valid

        news.url = 'http://example.com'
        expect(news).to be_valid
      end
    end

    describe 'published_at' do
      it 'presence: true' do
        news.published_at = nil
        expect(news).not_to be_valid
        expect(news.errors[:published_at]).not_to be_empty
      end
    end
  end

  describe 'スコープ' do
    describe '.recent' do
      it '公開日時の降順で並び替える' do
        old_news = create(:news, published_at: 2.days.ago)
        new_news = create(:news, published_at: 1.day.ago)

        expect(News.recent).to eq([new_news, old_news])
      end
    end
  end
end
