require 'rails_helper'

RSpec.describe News, type: :model do
  describe 'バリデーション' do
    let(:news) { build(:news) }

    describe 'title' do
      it 'タイトルが空の場合は無効になる' do
      news.title = nil
      expect(news).not_to be_valid
      expect(news.errors[:title]).not_to be_empty
      end

      it 'タイトルが正しく設定されている場合は有効になる' do
      news.title = '有効なタイトル'
      expect(news).to be_valid
      end
    end

    describe 'url' do
      context '無効な場合' do
        it 'URL が空の場合は無効になる' do
          news.url = nil
          expect(news).not_to be_valid
          expect(news.errors[:url]).not_to be_empty
        end

        it 'URL が重複している場合は無効になる' do
          create(:news, url: 'https://example.com/test')
          duplicate_news = build(:news, url: 'https://example.com/test')
          expect(duplicate_news).not_to be_valid
          expect(duplicate_news.errors[:url]).not_to be_empty
        end

        it 'URL形式でない場合は無効になる' do
          news.url = 'invalid-url'
          expect(news).not_to be_valid
          expect(news.errors[:url]).not_to be_empty
        end
      end

      context '有効な場合' do
        it 'HTTPSを許可する' do
          news.url = 'https://example.com'
          expect(news).to be_valid
        end

        it 'HTTPを許可する' do
          news.url = 'http://example.com'
          expect(news).to be_valid
        end
      end
    end

    describe 'published_at' do
      it '公開日時が空の場合は無効になる' do
      news.published_at = nil
      expect(news).not_to be_valid
      expect(news.errors[:published_at]).not_to be_empty
      end

      it '公開日時が正しく設定されている場合は有効になる' do
      news.published_at = Time.current
      expect(news).to be_valid
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
