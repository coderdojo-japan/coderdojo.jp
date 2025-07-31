require 'yaml'

namespace :news do
  desc 'db/news.yml を読み込んで News テーブルを upsert する'
  task import_from_yaml: :environment do
    yaml_path = Rails.root.join('db', 'news.yml')
    raw       = YAML.safe_load(File.read(yaml_path), permitted_classes: [Time], aliases: true)

    # entries を計算
    entries = raw['news'] || []
    new_count = 0
    updated_count = 0

    entries.each do |attrs|
      news = News.find_or_initialize_by(url: attrs['url'])
      is_new = news.new_record?

      news.assign_attributes(
        title:        attrs['title'],
        published_at: attrs['published_at']
      )
      
      if is_new || news.changed?
        news.save!
        if is_new
          new_count += 1
          status = 'new'
        else
          updated_count += 1
          status = 'updated'
        end
        puts "[News] #{news.published_at.to_date} #{news.title} (#{status})"
      end
    end

    puts "Imported #{new_count + updated_count} items (#{new_count} new, #{updated_count} updated)."
  end
end
