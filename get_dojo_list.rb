#!/usr/bin/env ruby

require 'net/http'
require 'json'

# Google Spreadsheet などから対象となった Dojo 名の列をコピーし、
# get_dojo_list.txt にペースト後、本スクリプトを実行すると、
# お知らせ記事などで使える HTML のリスト一覧が出力されます。
#
# 詳細: https://github.com/coderdojo-japan/coderdojo.jp/pull/1433

INPUT_TEXT = IO.readlines('./get_dojo_list.txt')
DOJO_DB    = JSON.parse Net::HTTP.get(URI.parse 'https://coderdojo.jp/dojos.json'), symbolize_names: true

# CoderDojo の名前を使って、Dojo 一覧からデータを検索
result    = '<h3>🎁️ 寄贈先の CoderDojo 一覧<small style="white-space: nowrap;">（カッコ内は都道府県名となります）</small></h3>'
result   << "\n\n<ul>\n"
dojo_name = ''
dojo_list = []
not_found = []

# Load and tweak dojo names from get_dojo_list.txt
INPUT_TEXT.each do |line|
  next if line.start_with?('#') || line.strip.empty?

  # Delete prefix like 'CoderDojo', fix 表記揺れ, etc.
  dojo_name = line
    .gsub(/codedojo/i,    '')
    .gsub(/coderdojo/i,   '')
    .gsub(/corderdojo/i,  '')        # 時々ある Typo
    .gsub(/コーダー道場/, '')
    .gsub('‪',            '')
    .gsub('　',           '')
    .gsub('＠',           '@')
    .gsub('（', '(').gsub('）', ')') # Ex: Anjo（愛知県）
    .gsub(/\(.*\)+/,      '')        #     Delete '(...)'
    .split('/').first                # Ex: 堺/泉北和泉
    .split('、').first               # Ex: 東大阪、八尾
    .strip

  # Search dojo data by its KANJI name from DOJO_DB (including inactive dojos).
  # MEMO: Use `.reverse` to find a latest dojo in case of overriding inactive dojo's name.
  found_dojo = DOJO_DB.reverse.find do |dojo|
    dojo[:name] == dojo_name.downcase
      .gsub('ishigaki',       '石垣')
      .gsub('hitachinaka',    'ひたちなか')
      .gsub('kodaira',        'こだいら')
      .gsub('toke',           '土気')
      .gsub('anjo',           '安城')
      .gsub('yabuki',         '矢吹')
      .gsub('nagareyama',     '流山')
      .gsub('minami-kashiwa', '南柏')
      .gsub('miyoshi',        '三好') # NOTE: 'Miyoshi' can be 三好 or 三次. Only 三好 uses 'Miyoshi' for now.
      .gsub('tsuruoka',       '鶴岡')
      .gsub('harumi',         '晴海')
      .gsub('町田',           'まちだ')
      .gsub('小平',           'こだいら')
      .gsub('八戸',           '八戸@吹上')
      .gsub('吉備岡山',       '吉備')
      .gsub('浦和@urawa minecraft club', '浦和@Urawa Minecraft Club')
  end

  (found_dojo && found_dojo[:is_active]) ?
    dojo_list << found_dojo :
    not_found << dojo_name
end

dojo_list.sort_by!{ |dojo| dojo[:order] }
result <<  dojo_list.map{ |dojo| "  <li><a href='#{dojo[:url]}'>#{dojo[:name]}</a><small>（#{dojo[:prefecture]}）</small></li>" }.join("\n")
result << "\n</ul>\n"
puts result

#binding.irb
# 検索して見つからなかった Dojo 一覧があれば出力
if not_found.any?
  puts ''
  puts '--- NOTE ---'
  puts "道場数: #{dojo_list.count}"
  not_found.each {|dojo_name| puts "Not-found or In-active: #{dojo_name}" }
end
