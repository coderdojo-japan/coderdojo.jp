require 'rails_helper'
require 'rake'

# 取得元が 200 で記事 0 件の RSS を返すと、合計の 1 割の下限をくぐって、その取得元の記事が DB から消える
# （PR TIMES の 14 件は 201 件の 7%）。取得元ごとに 0 件なら止める
RSpec.describe 'news:fetch の取得元ごとの 0 件' do
  # NOTE: 登録簿を新しくしてから読む。共有のまま load_tasks を重ねると、
  #       他の spec が読んだタスクの中身まで重ねて登録され、1 回の invoke で
  #       タスクが 2 回以上走る（2026年10月23日）
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

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
