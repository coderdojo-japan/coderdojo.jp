require 'yaml'

namespace :news do
  desc 'db/news.yml （またはENV指定のYAML）を読み込んで News テーブルを upsert する'
  task import_from_yaml: :environment do
    # ENVで上書き可能にする（なければデフォルト db/news.yml）
    yaml_path = ENV['NEWS_YAML_PATH'] ? Pathname.new(ENV['NEWS_YAML_PATH']) : Rails.root.join('db', 'news.yml')
    raw       = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time], aliases: true)

    # entries を計算
    entries = raw['news'] || []

    entries.each do |attrs|
      news = News.find_or_initialize_by(url: attrs['url'])
      news.assign_attributes(
        title:        attrs['title'],
        published_at: attrs['published_at']
      )
      news.save!
      puts "[news] #{news.published_at.to_date} #{news.title}"
    end

    puts "Imported #{entries.size} items."
  end
end
