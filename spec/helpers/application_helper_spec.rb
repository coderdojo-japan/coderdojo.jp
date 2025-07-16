require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_news_title' do
    it '先頭文字が絵文字ならそのまま、そうでなければ 📰 を付与する' do
      {
        '🔔 新着'      => '🔔 新着',
        '更新情報'      => '📰 更新情報',
        '1つ目のお知らせ' => '📰 1つ目のお知らせ'
      }.each do |input, expected|
        news = double('news', title: input)
        expect(helper.format_news_title(news)).to eq expected
      end
    end
  end
end
