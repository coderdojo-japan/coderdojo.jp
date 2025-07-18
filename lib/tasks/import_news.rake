require 'yaml'

namespace :news do
  desc "db/news.yml を読み込んで News テーブルを upsert する"
  task import_from_yaml: :environment do
    yaml_path = Rails.root.join('db', 'news.yml')
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
