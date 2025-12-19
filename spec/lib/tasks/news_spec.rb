require 'rails_helper'
require 'rake'

RSpec.describe 'news:upsert' do
  let(:news_yaml_path) { Rails.root.join('db', 'news.yml') }
  
  before(:all) do
    # Rakeタスクをロード
    Rails.application.load_tasks
  end
  
  before do
    # 既存のNewsレコードをクリア
    News.destroy_all
  end

  describe 'YAMLのIDとDBのIDの一致' do
    it 'YAMLファイルのIDがそのままDBのIDとして使用される' do
      # テスト用のYAMLデータを作成
      test_yaml_data = [
        {
          'id' => 10,
          'url' => 'https://example.com/news10',
          'title' => 'テストニュース10',
          'published_at' => '2025-12-10T09:00:00+09:00'
        },
        {
          'id' => 5,
          'url' => 'https://example.com/news5', 
          'title' => 'テストニュース5',
          'published_at' => '2025-12-05T09:00:00+09:00'
        },
        {
          'id' => 1,
          'url' => 'https://example.com/news1',
          'title' => 'テストニュース1',
          'published_at' => '2025-12-01T09:00:00+09:00'
        }
      ]

      # 一時的にYAMLファイルを置き換え
      original_yaml_content = File.read(news_yaml_path) if File.exist?(news_yaml_path)
      File.write(news_yaml_path, test_yaml_data.to_yaml)

      # タスクを実行
      Rake::Task['news:upsert'].execute

      # データベースのレコードを確認
      expect(News.count).to eq(3)
      
      # YAMLのIDとDBのIDが一致することを確認
      test_yaml_data.each do |yaml_item|
        db_news = News.find(yaml_item['id'])
        expect(db_news).not_to be_nil
        expect(db_news.id).to eq(yaml_item['id'])
        expect(db_news.url).to eq(yaml_item['url'])
        expect(db_news.title).to eq(yaml_item['title'])
      end

      # IDの配列が完全に一致することを確認
      yaml_ids = test_yaml_data.map { |item| item['id'] }.sort
      db_ids = News.pluck(:id).sort
      expect(db_ids).to eq(yaml_ids)

    ensure
      # 元のYAMLファイルを復元
      File.write(news_yaml_path, original_yaml_content) if original_yaml_content
    end

    it '既存レコードのIDも更新される' do
      # 既存のレコードを作成（異なるID）
      News.create!(id: 100, url: 'https://example.com/old', title: '古いニュース', published_at: 1.month.ago)
      
      # テスト用のYAMLデータ（同じURLだが異なるID）
      test_yaml_data = [
        {
          'id' => 1,
          'url' => 'https://example.com/old',
          'title' => '更新されたニュース',
          'published_at' => '2025-12-01T09:00:00+09:00'
        }
      ]

      # 一時的にYAMLファイルを置き換え
      original_yaml_content = File.read(news_yaml_path) if File.exist?(news_yaml_path)
      File.write(news_yaml_path, test_yaml_data.to_yaml)

      # タスクを実行
      Rake::Task['news:upsert'].execute

      # ID 100のレコードは削除され、ID 1のレコードが存在することを確認
      expect(News.exists?(100)).to be false
      expect(News.exists?(1)).to be true
      
      news = News.find(1)
      expect(news.title).to eq('更新されたニュース')

    ensure
      # 元のYAMLファイルを復元
      File.write(news_yaml_path, original_yaml_content) if original_yaml_content
    end

    it 'YAMLに存在しないレコードは削除される' do
      # YAMLに存在しないレコードを作成
      News.create!(id: 999, url: 'https://example.com/tobedeleted', title: '削除されるニュース', published_at: 1.day.ago)
      
      # テスト用のYAMLデータ（ID 999は含まない）
      test_yaml_data = [
        {
          'id' => 1,
          'url' => 'https://example.com/news1',
          'title' => 'テストニュース1',
          'published_at' => '2025-12-01T09:00:00+09:00'
        }
      ]

      # 一時的にYAMLファイルを置き換え
      original_yaml_content = File.read(news_yaml_path) if File.exist?(news_yaml_path)
      File.write(news_yaml_path, test_yaml_data.to_yaml)

      # タスクを実行
      Rake::Task['news:upsert'].execute

      # ID 999のレコードが削除されていることを確認
      expect(News.exists?(999)).to be false
      expect(News.count).to eq(1)
      expect(News.pluck(:id)).to eq([1])

    ensure
      # 元のYAMLファイルを復元
      File.write(news_yaml_path, original_yaml_content) if original_yaml_content
    end
  end

  # Rakeタスクをテストごとにリロード
  before do
    Rake.application.tasks.each do |task|
      task.reenable if task.name.start_with?('news:')
    end
  end
end