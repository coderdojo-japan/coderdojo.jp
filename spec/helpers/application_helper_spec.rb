require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_news_title' do
    it '先頭文字が絵文字ならそのまま返す' do
      news = double('news', title: '🔔 新着', url: 'https://news.coderdojo.jp/123')
      expect(helper.format_news_title(news)).to eq '🔔 新着'
    end

    context '先頭文字が絵文字でない場合' do
      it 'ポッドキャストのURLには📻を付与する' do
        news = double('news', title: 'エピソード33', url: 'https://coderdojo.jp/podcasts/33')
        expect(helper.format_news_title(news)).to eq '📻 エピソード33'
      end

      it 'PR TIMESのURLには📢を付与する' do
        news = double('news', title: 'プレスリリース', url: 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html')
        expect(helper.format_news_title(news)).to eq '📢 プレスリリース'
      end

      it 'その他のURLには📰を付与する' do
        news = double('news', title: '更新情報', url: 'https://news.coderdojo.jp/2025/12/06/dojoletter')
        expect(helper.format_news_title(news)).to eq '📰 更新情報'
      end
    end
  end

  describe '#news_link_url' do
    it 'ポッドキャストの絶対URLを相対パスに変換する' do
      news = double('news', url: 'https://coderdojo.jp/podcasts/33')
      expect(helper.news_link_url(news)).to eq '/podcasts/33'
    end

    it 'その他のURLはそのまま返す' do
      news = double('news', url: 'https://news.coderdojo.jp/2025/12/06/dojoletter')
      expect(helper.news_link_url(news)).to eq 'https://news.coderdojo.jp/2025/12/06/dojoletter'
      
      news2 = double('news', url: 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html')
      expect(helper.news_link_url(news2)).to eq 'https://prtimes.jp/main/html/rd/p/000000001.000038935.html'
    end
  end
end
