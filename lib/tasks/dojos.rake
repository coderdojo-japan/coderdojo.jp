#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'yaml'

namespace :dojos do
  desc 'Parseから出力したjsonファイルをベースに、yamlファイルを生成します'
  task generate_yaml: :environment do
    dojos = JSON.parse(File.read(Rails.root.join('db', 'parse_backup.json')))['results']
    dojos.sort_by!{ |hash| hash['order'] }

    # Tweak dojo info if needed
    dojos.each do |dojo|
      dojo['description'].strip!
      dojo.delete 'objectId'  # Delete Parse-specific key
      dojo.delete 'createdAt' # This is managed by database
      dojo.delete 'updatedAt' # This is managed by database
    end

    YAML.dump(dojos, File.open(Rails.root.join('db', 'dojos.yaml'), 'w'))
  end

  desc '現在のyamlファイルを元にデータベースを更新します'
  task update_db_by_yaml: :environment do
    dojos = YAML.load_file(Rails.root.join('db','dojos.yaml'))
    dojos.sort_by{ |hash| hash['order'] }

    dojos.each do |dojo|
      d = Dojo.find_by(name: dojo['name']) || Dojo.new

      d.id          = dojo['id']
      d.name        = dojo['name']
      d.email       = ''
      d.order       = dojo['order']
      d.description = dojo['description']
      d.logo        = dojo['logo']
      d.tags        = dojo['tags']
      d.url         = dojo['url']
      d.created_at  = dojo['createdAt'] ? Time.zone.parse(dojo['createdAt']) : Time.zone.now
      d.updated_at  = Time.zone.now

      d.save!
    end
  end

  desc '現在のyamlファイルのカラムをソートします'
  task sort_yaml: :environment do
    dojos = YAML.load_file(Rails.root.join('db','dojos.yaml'))

    # Dojo column should start with 'name' for human-readability
    dojos.map! do |dojo|
      dojo.sort_by{|a,b| a.last}.to_h
    end

    YAML.dump(dojos, File.open(Rails.root.join('db', 'dojos.yaml'), 'w'))
  end

  desc 'DBからyamlファイルを生成します'
  task migrate_adding_id_to_yaml: :environment do
    dojos = YAML.load_file(Rails.root.join('db','dojos.yaml'))

    dojos.map! do |dojo|
      d = Dojo.find_by(name: dojo['name'])
      new_dojo = {}
      new_dojo['id'] = d.id
      new_dojo.merge!(dojo)
      new_dojo
    end

    YAML.dump(dojos, File.open(Rails.root.join('db', 'dojos.yaml'), 'w'))
  end
end
