#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'json'
require 'yaml'
require 'csv'

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


    Dojo.dump_attributes_to_yaml(dojos)
  end

  desc '現在のyamlファイルを元にデータベースを更新します'
  task update_db_by_yaml: :environment do
    dojos = Dojo.load_attributes_from_yaml

    dojos.each do |dojo|
      d = Dojo.find_or_initialize_by(id: dojo['id'])

      d.name        = dojo['name']
      d.email       = ''
      d.order       = set_order( dojo['order'] ?  dojo['order']: dojo['name'])
      d.description = dojo['description']
      d.logo        = dojo['logo']
      d.tags        = dojo['tags']
      d.url         = dojo['url']
      d.created_at  = d.new_record? ? Time.zone.now : dojo['created_at'] || d.created_at
      d.updated_at  = Time.zone.now
      d.prefecture_id = dojo['prefecture_id']

      d.save!
    end
  end

  # search order number for google spred sheets
  # 'yamlファイルのnameからorderの値を生成します'
  def set_order(pre_city)

    return pre_city if  pre_city =~ /^[0-9]+$/

    if /(?<city>.+)\s\(.+\)/ =~ pre_city
      table = CSV.table(Rails.root.join('db','city_code.csv'))
      row = table.find{ |r| r[:city].to_s.start_with?(city)}
      row ? row[:order] : raise("Can't searched order by #{pre_city}")
    else
      raise("It is not valid data for #{pre_city}")
    end
  end

  desc '現在のyamlファイルのカラムをソートします'
  task sort_yaml: :environment do
    dojos = Dojo.load_attributes_from_yaml

    # Dojo column should start with 'name' for human-readability
    dojos.map! do |dojo|
      dojo.sort_by{|a,b| a.last}.to_h
    end

    Dojo.dump_attributes_to_yaml(dojos)
  end

  desc 'DBからyamlファイルを生成します'
  task migrate_adding_id_to_yaml: :environment do
    dojos = Dojo.load_attributes_from_yaml

    dojos.map! do |dojo|
      d = Dojo.find_by(name: dojo['name'])
      new_dojo = {}
      new_dojo['id'] = d.id
      new_dojo.merge!(dojo)
      new_dojo
    end

    Dojo.dump_attributes_to_yaml(dojos)
  end
end
