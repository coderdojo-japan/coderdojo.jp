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

# CoderDojo "名前を使って、Dojo 一覧からデータを検索
result    = "<h3>🎁️ 寄贈先の CoderDojo 一覧<small style='white-space: nowrap;'>（カッコ内は都道府県名となります）</small></h3>\n\n"
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
    .gsub(/coder dojo/i,   '')
    .gsub(/コーダー道場/, '')
    .gsub(/コードー道場/, '')
    .gsub(/コーダードージョー/, '')
    .gsub('‪',            '')
    .gsub('　',           '')
    .gsub('＠',           '@')
    .gsub('（', '(').gsub('）', ')') # Ex: Anjo（愛知県）
    .gsub(/\(.*\)+/,      '')        #     Delete '(...)'
    .split('/').first                # Ex: 堺/泉北和泉
    .split('、').first               # Ex: 東大阪、八尾
    .strip

  # Search dojo data by its KANJI name from DOJO_DB (including inactive dojos).
  # MEMO: Same dojo name can exist like 南風原 (old: inacive, new: active).
  found_dojo = DOJO_DB.find do |dojo|
    dojo[:name] == dojo_name.downcase
      .gsub('aizu',           '会津')
      .gsub('anjo',           '安城')
      .gsub('harumi',         '晴海')
      .gsub('hitachinaka',    'ひたちなか')
      .gsub('ishigaki',       '石垣')
      .gsub('kodaira',        'こだいら')
      .gsub('nagareyama',     '流山')
      .gsub('minami-kashiwa', '南柏')
      .gsub('miyoshi',        '三好') # NOTE: 'Miyoshi' can be 三好 or 三次. Only 三好 uses 'Miyoshi' for now.
      .gsub('tempaku',        '天白')
      .gsub('toke',           '土気')
      .gsub('tokushima',      '徳島')
      .gsub('tsuruoka',       '鶴岡')
      .gsub('yabuki',         '矢吹')
      .gsub('まつど',         '松戸')
      .gsub('高岡',           'たかおか')
      .gsub('町田',           'まちだ')
      .gsub('小平',           'こだいら')
      .gsub('八戸',           '八戸@吹上')
      .gsub('八尾@yotteco',   '八尾')
      .gsub('平野',           '平野@YOZORA LABO')
      .gsub('麹町',           '麹町@アドバンスト・ソフト')
      .gsub('吉備okayama',    '吉備')
      .gsub('吉備岡山',       '吉備')
      .gsub('名護 恩納@oist', '名護')
      .gsub('urawa',                     '浦和@Urawa Minecraft Club')
      .gsub('浦和',                      '浦和@Urawa Minecraft Club')
      .gsub('浦和@urawa minecraft club', '浦和@Urawa Minecraft Club')
      .gsub('南風原',         '南風原')
  end

  # Show all dojos, including in-active dojos, if SHOW_ALL mode
  if ENV['SHOW_ALL'].eql?('true')
    (found_dojo) ?
      dojo_list << found_dojo :
      not_found << dojo_name
  else
    (found_dojo && found_dojo[:is_active]) ?
      dojo_list << found_dojo :
      not_found << dojo_name
  end
end

# coderdojo.jp の掲載順と同じ順序に揃える
dojo_list.sort_by!{ |dojo| dojo[:order] }

# 掲載方式 v1（リスト形式）e.g. https://news.coderdojo.jp/2022/07/12/donation-from-box-to-coderdojo/
#result << "\n\n<ul>\n"
#result <<  dojo_list.map{ |dojo| "  <li><a href='#{dojo[:url]}'>#{dojo[:name]}</a><small>（#{dojo[:prefecture]}）</small></li>" }.join("\n")
#result << "\n</ul>\n"

# 掲載方式 v2（表形式）e.g. https://news.coderdojo.jp/2024/12/25/box-japan-to-coderdojo/
result << "<table style='margin: auto; border-collapse: separate; border-spacing: 20px; table-layout: fixed; width: 98%;'>\n"
result << "  <tbody>\n"
dojo_list.each_with_index do |dojo, i|p
  result << "    <tr>\n"  if i%3 == 0
  result << <<-DOJO_HTML
      <td style='text-align: center; width: 33%;'>
        <a href='#{dojo[:url]}'>
          <img src='#{dojo[:logo].gsub('.webp', '.png')}' width='100px'/><br>
          <span style='font-weight: bolder;'>#{dojo[:name]}<br><small> (#{dojo[:prefecture]})</small></span>
        </a>
      </td>
  DOJO_HTML
  result << "    </tr>\n" if i%3 == 2 || i == dojo_list.size - 1
end
result << "  </tbody>\n"
result << "</table>"

puts result

# デバッグ用コード -- 見つからなかった Dojo 等あれば出力
puts ''
puts '--- NOTE ---'
puts "道場数: #{dojo_list.count}"
not_found.each {|dojo_name| puts "Not-found or In-active: #{dojo_name}" }

