require 'rails_helper'
require 'rake'

# 取得元が 200 を返しても記事の一部しか返さないと、db/news.yml が縮み、デプロイ時の news:upsert が
# DB から記事を消す（2025年11月に 147 件 → 0 件、2026年10月に 201 件 → 49 件）。前回から大きく減ったら止める
RSpec.describe 'news:fetch の件数の下限' do
  before(:all) { Rails.application.load_tasks }

  let(:news_yaml_path) { Rails.root.join('db', 'news.yml') }
  let(:task) { Rake::Task['news:fetch'] }

  around do |example|
    original = File.read(news_yaml_path)
    example.run
  ensure
    File.write(news_yaml_path, original)
  end

  after { task.reenable }

  def write_yaml_with(count)
    items = (1..count).map { |i| { 'id' => i, 'url' => "https://example.com/#{i}", 'title' => "記事 #{i}", 'published_at' => '2026-10-01T09:00:00+09:00' } }
    File.write(news_yaml_path, items.to_yaml)
  end

  # テスト用の RSS（spec/fixtures/sample_news.rss）は 3 件
  it '前回より 1 割以上減ったら止め、YAML を書き換えない' do
    write_yaml_with(10)

    expect { task.invoke }.to raise_error(/10 件 → 3 件/)
    expect(YAML.load_file(news_yaml_path).size).to eq 10
  end

  it '1 割未満の減少（記事の削除など）は受け入れる' do
    write_yaml_with(3)

    expect { task.invoke }.not_to raise_error
    expect(YAML.load_file(news_yaml_path).size).to eq 3
  end
end
