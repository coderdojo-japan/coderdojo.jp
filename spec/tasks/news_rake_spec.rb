require 'rails_helper'
require 'rake'
require 'yaml'

RSpec.describe 'news Rakeタスク', type: :task do
  before { Rails.application.load_tasks }
  before { allow(Rails.env).to receive(:test?).and_return(true) }

  # テスト用に tmp/news.yml を使う
  let(:yaml_path)    { Rails.root.join('tmp', 'news.yml') }
  let(:fetch_task)   { Rake::Task['news:fetch'] }
  let(:import_task)  { Rake::Task['news:import_from_yaml'] }
  let(:yaml_content) { YAML.safe_load(File.read(yaml_path), permitted_classes: [Time]) }

  around do |example|
    # テスト前後に一度だけ tmp/news.yml をクリア
    File.delete(yaml_path) if File.exist?(yaml_path)
    example.run
    File.delete(yaml_path) if File.exist?(yaml_path)
  end

  describe 'news:fetch タスク' do
    before do
      ENV['NEWS_YAML_PATH'] = yaml_path.to_s
      ENV['NEWS_RSS_PATH']  = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
      fetch_task.reenable
    end

    after do
      ENV.delete('NEWS_YAML_PATH')
      ENV.delete('NEWS_RSS_PATH')
    end

    it 'サンプルRSSからニュースを取得し YAML に書き込む' do
      expect { fetch_task.invoke }.not_to raise_error
      expect(File.exist?(yaml_path)).to be true
      expect(yaml_content['news']).to be_an(Array)
      expect(yaml_content['news'].size).to eq(3)
    end

    it 'ID が 1 から連番で付与される' do
      fetch_task.invoke
      ids = yaml_content['news'].map { |item| item['id'] }
      expect(ids).to eq([1, 2, 3])
    end

    it '公開日時で降順ソートされる' do
      fetch_task.invoke
      dates = yaml_content['news'].map { |item| Time.parse(item['published_at']) }
      expect(dates).to eq(dates.sort.reverse)
    end
  end

  describe 'news:import_from_yaml タスク' do
    let(:news_data) do
      {
        'news' => [
          { 'id' => 1, 'url' => 'https://example.com/test1', 'title' => 'テスト記事1', 'published_at' => '2025-01-01T10:00:00Z' },
          { 'id' => 2, 'url' => 'https://example.com/test2', 'title' => 'テスト記事2', 'published_at' => '2025-01-02T10:00:00Z' }
        ]
      }
    end

    before do
      ENV['NEWS_YAML_PATH'] = yaml_path.to_s
      File.write(yaml_path, news_data.to_yaml)
      import_task.reenable
    end

    after do
      ENV.delete('NEWS_YAML_PATH')
    end

    it 'YAML ファイルから News レコードを新規作成する' do
      expect { import_task.invoke }.to change(News, :count).by(2)
      expect(News.find_by(url: news_data['news'][0]['url']).title).to eq('テスト記事1')
      expect(News.find_by(url: news_data['news'][1]['url']).title).to eq('テスト記事2')
    end

    it '既存レコードがあれば属性を更新する' do
      create(:news, url: news_data['news'][0]['url'], title: '古いタイトル')
      expect { import_task.invoke }.to change(News, :count).by(1)
      expect(News.find_by(url: news_data['news'][0]['url']).title).to eq('テスト記事1')
    end
  end
end
