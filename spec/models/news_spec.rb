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

  describe '#formatted_title' do
    it '先頭文字が絵文字ならそのまま返す' do
      news = build(:news, title: '🔔 新着', url: 'https://news.coderdojo.jp/123')
      expect(news.formatted_title).to eq '🔔 新着'
    end

    context '先頭文字が絵文字でない場合' do
      it 'タイトルに「寄贈」が含まれる場合は🎁を付与する' do
        news = build(:news, title: 'ノートPC 233台を寄贈しました', url: 'https://news.coderdojo.jp/2025/12/18/pc-donation')
        expect(news.formatted_title).to eq '🎁 ノートPC 233台を寄贈しました'
      end

      it 'ポッドキャストURLはタイトルの「寄贈」より優先される' do
        news = build(:news, title: 'ポッドキャストで寄贈について話しました', url: 'https://coderdojo.jp/podcasts/50')
        expect(news.formatted_title).to eq '📻 ポッドキャストで寄贈について話しました'
      end

      it 'ポッドキャストのURLには📻を付与する' do
        news = build(:news, title: 'エピソード33', url: 'https://coderdojo.jp/podcasts/33')
        expect(news.formatted_title).to eq '📻 エピソード33'
      end

      it 'PR TIMESのURLには📢を付与する' do
        news = build(:news, title: 'プレスリリース', url: 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html')
        expect(news.formatted_title).to eq '📢 プレスリリース'
      end

      it 'その他のURLには📰を付与する' do
        news = build(:news, title: '更新情報', url: 'https://news.coderdojo.jp/2025/12/06/dojoletter')
        expect(news.formatted_title).to eq '📰 更新情報'
      end
    end
  end

  describe '#link_url' do
    it 'ポッドキャストの絶対URLを相対パスに変換する' do
      news = build(:news, url: 'https://coderdojo.jp/podcasts/33')
      expect(news.link_url).to eq '/podcasts/33'
    end

    it 'その他のURLはそのまま返す' do
      news = build(:news, url: 'https://news.coderdojo.jp/2025/12/06/dojoletter')
      expect(news.link_url).to eq 'https://news.coderdojo.jp/2025/12/06/dojoletter'
      
      news2 = build(:news, url: 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html')
      expect(news2.link_url).to eq 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html'
    end
  end

  describe '#internal_link?' do
    context '内部リンクの場合' do
      it 'coderdojo.jpドメインのURLはtrueを返す' do
        news = build(:news, url: 'https://coderdojo.jp/podcasts/33')
        expect(news.internal_link?).to be true
      end

      it '相対パスで始まるURLはtrueを返す' do
        news = build(:news, url: '/kata')
        expect(news.internal_link?).to be true
      end
    end

    context '外部リンクの場合' do
      it 'news.coderdojo.jpサブドメインはfalseを返す' do
        news = build(:news, url: 'https://news.coderdojo.jp/2025/12/06/dojoletter')
        expect(news.internal_link?).to be false
      end

      it 'prtimes.jpドメインはfalseを返す' do
        news = build(:news, url: 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html')
        expect(news.internal_link?).to be false
      end

      it '他の外部ドメインはfalseを返す' do
        news = build(:news, url: 'https://example.com/article')
        expect(news.internal_link?).to be false
      end
    end
  end
end
