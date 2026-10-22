require 'rails_helper'
require 'rake'

# 取得元が 200 で記事 0 件の RSS を返すと、合計の 1 割の下限をくぐって、その取得元の記事が DB から消える
# （PR TIMES の 14 件は 201 件の 7%）。取得元ごとに 0 件なら止める
RSpec.describe 'news:fetch の取得元ごとの 0 件' do
  before(:all) { Rails.application.load_tasks }

  let(:empty_feed) { Rails.root.join('spec', 'fixtures', 'empty_news.rss').to_s }

  it 'PR TIMES が 0 件なら止める' do
    expect { send(:fetch_prtimes_posts, empty_feed) }.to raise_error(/PR TIMES.*0 件/)
  end

  it 'DojoCast が 0 件なら止める' do
    expect { send(:fetch_podcast_posts, empty_feed) }.to raise_error(/DojoCast.*0 件/)
  end

  it 'news.coderdojo.jp が 0 件なら止める' do
    response = Net::HTTPOK.new('1.1', '200', 'OK')
    allow(response).to receive(:body).and_return('[]')
    response['X-WP-TotalPages'] = '0'
    allow(Net::HTTP).to receive(:get_response).and_return(response)

    expect { send(:fetch_dojo_news_posts, 'https://news.example.com/wp-json/wp/v2/posts') }.to raise_error(/WordPress API.*0 件/)
  end
end
