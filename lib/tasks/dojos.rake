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
end
