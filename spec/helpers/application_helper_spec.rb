require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_news_title' do
    it '先頭文字が絵文字ならそのまま返す' do
      news = double('news', title: '🔔 新着', url: 'https://news.coderdojo.jp/123')
      expect(helper.format_news_title(news)).to eq '🔔 新着'
    end

    context '先頭文字が絵文字でない場合' do
      it 'ポッドキャストのURLには📻を付与する' do
        news = double('news', title: 'DojoCast Episode 33', url: 'https://podcasters.spotify.com/pod/show/coderdojo-japan/episodes/033')
        expect(helper.format_news_title(news)).to eq '📻 DojoCast Episode 33'
        
        news2 = double('news', title: 'エピソード33', url: 'https://coderdojo.jp/podcasts/33')
        expect(helper.format_news_title(news2)).to eq '📻 エピソード33'
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
end
