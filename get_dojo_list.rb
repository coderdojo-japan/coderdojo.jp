#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'pry'

# Google Spreadsheet などから対象となった Dojo 名の列をコピーし、
# get_dojo_list.txt にペースト後、本スクリプトを実行すると、
# お知らせ記事などで使える HTML のリスト一覧が出力されます。
#
# 詳細: https://github.com/coderdojo-japan/coderdojo.jp/pull/1433

TEXT   = IO.readlines('./get_dojo_list.txt')
DOJOS  = JSON.parse(Net::HTTP.get URI.parse('https://coderdojo.jp/dojos.json'))
result = "<ul>\n"

# CoderDojo の名前を使って、Dojo 一覧からデータを検索
dojo_name =''
not_found = []
TEXT.each do |line|
  next if line.start_with?('#') || line.strip.empty?
  dojo_name = line.split[1..].join
  dojo_data = DOJOS.find {|dojo| dojo['name'].start_with? dojo_name}
  not_found << dojo_name && next if dojo_data.nil?
  result << "  <li>#{dojo_data['linked_text']}</li>\n"
  #result << "  <li>#{d['linked_text']}</li>\n"
end
result << "</ul>\n"
puts result

# 検索して見つからなかった Dojo 一覧があれば出力
puts '---' if not_found.nil?
not_found.each {|dojo_name| puts "Not found: #{dojo_name}" }
