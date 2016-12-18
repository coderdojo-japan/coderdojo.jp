#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'yaml'

namespace :dojos do
  desc 'Parseから出力したjsonファイルを整形し、yamlファイルに変換します'
  task to_yaml: :environment do
    dojos = JSON.parse(File.read(Rails.root.join('db', 'parse_backup.json')))['results']
    dojos.sort_by!{ |hash| hash['order'] }

    # Tweak dojo info if needed
    dojos.each do |dojo|
      dojo['description'].strip!
      dojo.delete 'objectId' # Delete Parse-specific key
    end

    YAML.dump(dojos, File.open(Rails.root.join('db', 'dojos.yaml'), 'w'))
  end

  desc '現在のyamlファイルを元にデータベースを更新します'
  task update_db_by_yaml: :environment do
    dojos = YAML.load_file(Rails.root.join('db','dojos.yaml'))
    dojos.sort_by{ |hash| hash['createdAt'] }

    dojos.each do |dojo|
      d = Dojo.find_by(name: dojo['name']) || Dojo.new

      d.name        = dojo['name']
      d.email       = ''
      d.order       = dojo['order']
      d.description = dojo['description']
      d.logo        = dojo['image_url']
      d.tags        = dojo['tags']
      d.url         = dojo['url']
      d.created_at  = Time.zone.parse(dojo['createdAt'])
      d.updated_at  = Time.zone.parse(dojo['createdAt'])

      d.save!
    end
  end
end
