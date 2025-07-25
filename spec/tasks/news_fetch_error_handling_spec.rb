require 'rails_helper'
require 'rake'
require 'yaml'
require 'net/http'

RSpec.describe 'news:fetch エラーハンドリング', type: :task do
  before { Rails.application.load_tasks }
  before { allow(Rails.env).to receive(:test?).and_return(true) }

  let(:yaml_path)   { Rails.root.join('tmp', 'error_test_news.yml') }
  let(:fetch_task)  { Rake::Task['news:fetch'] }
  let(:logger_mock) { instance_double(ActiveSupport::BroadcastLogger) }

  around do |example|
    File.delete(yaml_path) if File.exist?(yaml_path)
    example.run
    File.delete(yaml_path) if File.exist?(yaml_path)
  end

  before do
    ENV['NEWS_YAML_PATH'] = yaml_path.to_s
    fetch_task.reenable
    allow(ActiveSupport::BroadcastLogger).to receive(:new).and_return(logger_mock)
    allow(logger_mock).to receive(:info)
    allow(logger_mock).to receive(:warn)
  end

  after do
    ENV.delete('NEWS_YAML_PATH')
    ENV.delete('NEWS_RSS_PATH')
  end

  describe 'ネットワーク・RSSエラー時の挙動' do
    context 'ネットワークエラーの場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://invalid-url.example.com/rss'
        allow(self).to receive(:safe_open).and_raise(Net::OpenTimeout, '接続タイムアウト')
      end

      it 'warnログを出し、空のnews.ymlを生成する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+/)
        expect { fetch_task.invoke }.not_to raise_error
        yaml = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml['news']).to eq([])
      end
    end

    context 'RSS::Parser.parseが失敗する場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        allow(self).to receive(:safe_open).and_return('<invalid>not valid rss</invalid>')
      end

      it 'warnログを出し、空のnews.ymlを生成する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+/)
        expect { fetch_task.invoke }.not_to raise_error
        yaml = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml['news']).to eq([])
      end
    end

    context '空のRSSフィードの場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        empty_rss = <<~RSS
          <?xml version="1.0" encoding="UTF-8"?>
          <rss version="2.0">
            <channel>
              <title>Empty Feed</title>
              <description>Empty RSS Feed</description>
              <link>https://example.com</link>
            </channel>
          </rss>
        RSS
        allow(self).to receive(:safe_open).and_return(empty_rss)
      end

      it '空配列でnews.ymlを生成する' do
        expect { fetch_task.invoke }.not_to raise_error
        yaml = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml['news']).to eq([])
      end
    end
  end

  describe '破損したYAMLファイルのハンドリング' do
    context '既存のYAMLが破損している場合' do
      before do
        ENV['NEWS_RSS_PATH'] = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
        File.write(yaml_path, "invalid yaml content:\n  - broken\n  indentation:\n    - here")
      end

      it 'YAML読み込みエラーが発生し、タスクが失敗する' do
        expect { fetch_task.invoke }.to raise_error(Psych::SyntaxError)
      end
    end

    context '既存のYAMLが不正な構造の場合' do
      before do
        ENV['NEWS_RSS_PATH'] = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
        File.write(yaml_path, { 'invalid_key' => [{ 'id' => 1 }] }.to_yaml)
      end

      it '空配列として扱い、正常に上書きされる' do
        expect { fetch_task.invoke }.not_to raise_error
        yaml = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml['news']).to be_an(Array)
        expect(yaml['news'].size).to be > 0
      end
    end
  end
end
