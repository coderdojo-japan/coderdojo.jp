require 'rails_helper'
require 'rake'
require 'yaml'
require 'net/http'

RSpec.describe 'news:fetch エラーハンドリング', type: :task do
  before { Rails.application.load_tasks }
  before { allow(Rails.env).to receive(:test?).and_return(true) }

  let(:yaml_path)    { Rails.root.join('tmp', 'error_test_news.yml') }
  let(:fetch_task)   { Rake::Task['news:fetch'] }
  let(:logger_mock)  { instance_double(ActiveSupport::BroadcastLogger) }

  before do
    ENV['NEWS_YAML_PATH'] = yaml_path.to_s
    fetch_task.reenable
    
    # ロガーのモック設定
    allow(ActiveSupport::BroadcastLogger).to receive(:new).and_return(logger_mock)
    allow(logger_mock).to receive(:info)
    allow(logger_mock).to receive(:warn)
  end

  after do
    ENV.delete('NEWS_YAML_PATH')
    ENV.delete('NEWS_RSS_PATH')
    File.delete(yaml_path) if File.exist?(yaml_path)
  end

  describe 'ネットワークエラーのハンドリング' do
    context 'safe_open がネットワークエラーで例外を投げる場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        allow_any_instance_of(Object).to receive(:safe_open).and_raise(Net::OpenTimeout, '接続タイムアウト')
      end

      it 'エラーをログに記録し、処理を継続する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+: 接続タイムアウト/)
        expect { fetch_task.invoke }.not_to raise_error
        
        # 空の news.yml が作成される
        expect(File.exist?(yaml_path)).to be true
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news']).to eq([])
      end
    end

    context 'HTTPエラーレスポンスの場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        allow_any_instance_of(Object).to receive(:safe_open).and_raise(Net::HTTPServerException, '500 Internal Server Error')
      end

      it 'エラーをログに記録し、処理を継続する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+: 500 Internal Server Error/)
        expect { fetch_task.invoke }.not_to raise_error
      end
    end

    context '不正なURLの場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        allow_any_instance_of(Object).to receive(:safe_open).and_raise('不正なURLです: https://example.com/feed.rss')
      end

      it 'エラーをログに記録し、処理を継続する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+: 不正なURLです/)
        expect { fetch_task.invoke }.not_to raise_error
      end
    end
  end

  describe '不正なRSSのハンドリング' do
    context 'RSS::Parser.parse が失敗する場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        
        # safe_open は成功するが、不正なXMLを返す
        allow_any_instance_of(Object).to receive(:safe_open).and_return('<invalid>not valid rss</invalid>')
      end

      it 'エラーをログに記録し、処理を継続する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+: /)
        expect { fetch_task.invoke }.not_to raise_error
        
        # 空の news.yml が作成される
        expect(File.exist?(yaml_path)).to be true
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news']).to eq([])
      end
    end

    context '空のRSSフィードの場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        
        # 有効だが空のRSSフィード
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
        
        allow_any_instance_of(Object).to receive(:safe_open).and_return(empty_rss)
      end

      it '空の配列として処理し、エラーにならない' do
        expect { fetch_task.invoke }.not_to raise_error
        
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news']).to eq([])
      end
    end

    context 'RSSアイテムに必須フィールドが欠けている場合' do
      before do
        ENV['NEWS_RSS_PATH'] = 'https://example.com/feed.rss'
        
        # linkやpubDateが欠けているRSS
        invalid_rss = <<~RSS
          <?xml version="1.0" encoding="UTF-8"?>
          <rss version="2.0">
            <channel>
              <title>Invalid Feed</title>
              <description>Invalid RSS Feed</description>
              <link>https://example.com</link>
              <item>
                <title>タイトルのみの記事</title>
                <!-- link と pubDate が欠けている -->
              </item>
            </channel>
          </rss>
        RSS
        
        allow_any_instance_of(Object).to receive(:safe_open).and_return(invalid_rss)
      end

      it 'エラーをログに記録し、処理を継続する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+/)
        expect { fetch_task.invoke }.not_to raise_error
      end
    end
  end

  describe '破損したYAMLファイルのハンドリング' do
    context '既存のYAMLファイルが破損している場合' do
      before do
        ENV['NEWS_RSS_PATH'] = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
        
        # 破損したYAMLファイルを作成
        File.write(yaml_path, "invalid yaml content:\n  - broken\n  indentation:\n    - here")
      end

      it 'YAML読み込みエラーが発生し、タスクが失敗する' do
        # YAML.safe_load のエラーは rescue されないため、タスク全体が失敗する
        expect { fetch_task.invoke }.to raise_error(Psych::SyntaxError)
      end
    end

    context '既存のYAMLファイルが不正な構造の場合' do
      before do
        ENV['NEWS_RSS_PATH'] = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
        
        # 不正な構造のYAMLファイル（newsキーがない）
        File.write(yaml_path, { 'invalid_key' => [{ 'id' => 1 }] }.to_yaml)
      end

      it '空の配列として扱い、処理を継続する' do
        expect { fetch_task.invoke }.not_to raise_error
        
        # 新しいデータで上書きされる
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news']).to be_an(Array)
        expect(yaml_content['news'].size).to be > 0
      end
    end

    context '許可されていないクラスを含むYAMLファイルの場合' do
      before do
        ENV['NEWS_RSS_PATH'] = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
        
        # DateTimeオブジェクトを含むYAML（Timeのみ許可されている）
        yaml_content = {
          'news' => [
            {
              'id' => 1,
              'url' => 'https://example.com/test',
              'title' => 'テスト',
              'published_at' => DateTime.now
            }
          ]
        }
        
        # 強制的にDateTimeオブジェクトを含むYAMLを作成
        File.write(yaml_path, yaml_content.to_yaml.gsub('!ruby/object:DateTime', '!ruby/object:DateTime'))
      end

      it 'YAML読み込みエラーが発生し、タスクが失敗する' do
        expect { fetch_task.invoke }.to raise_error(Psych::DisallowedClass)
      end
    end
  end

  describe '複数のエラーが同時に発生する場合' do
    context '複数のRSSフィードで異なるエラーが発生する場合' do
      before do
        # 複数のフィードURLを環境変数経由では設定できないため、
        # デフォルトの動作をオーバーライドする
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Rails.env).to receive(:staging?).and_return(false)
        ENV.delete('NEWS_RSS_PATH')
        
        # 最初のフィードはネットワークエラー
        allow_any_instance_of(Object).to receive(:safe_open)
          .with('https://news.coderdojo.jp/feed/')
          .and_raise(Net::OpenTimeout, 'タイムアウト')
      end

      it '各エラーをログに記録し、処理を継続する' do
        expect(logger_mock).to receive(:warn).with(/⚠️ Failed to fetch .+: タイムアウト/)
        expect { fetch_task.invoke }.not_to raise_error
        
        # 空の news.yml が作成される
        expect(File.exist?(yaml_path)).to be true
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news']).to eq([])
      end
    end
  end

  describe 'エラーリカバリー' do
    context 'ネットワークエラー後に再実行した場合' do
      before do
        ENV['NEWS_RSS_PATH'] = Rails.root.join('spec', 'fixtures', 'sample_news.rss').to_s
      end

      it '正常に処理される' do
        # 最初はネットワークエラー
        allow_any_instance_of(Object).to receive(:safe_open).and_raise(Net::OpenTimeout, 'タイムアウト')
        expect { fetch_task.invoke }.not_to raise_error
        
        # エラー時は空のYAMLが作成される
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news']).to eq([])
        
        # safe_openのモックを解除して正常動作に戻す
        allow_any_instance_of(Object).to receive(:safe_open).and_call_original
        
        # タスクを再実行可能にする
        fetch_task.reenable
        
        # 再実行すると正常に処理される
        expect { fetch_task.invoke }.not_to raise_error
        yaml_content = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time])
        expect(yaml_content['news'].size).to be > 0
      end
    end
  end
end