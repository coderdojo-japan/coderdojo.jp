# For Kodaira's dojo event histories
# NOTE: This needs google_drive gem.
# Exec: `gem install google_drive`
#
# Google spread sheet url
# https://docs.google.com/spreadsheets/d/15oTUF20IBQ99taJb3BO10Xpbn0tR-c_xmTJQUwH2M38/edit#gid=1633991574
#
# google-drive-ruby(for Google API)
# https://github.com/gimite/google-drive-ruby/blob/bc8d27b1c4f7369bba6e308525377444c3932364/doc/authorization.md#on-behalf-of-you-command-line-authorization

SPREAD_SHEET_KEY = '15oTUF20IBQ99taJb3BO10Xpbn0tR-c_xmTJQUwH2M38'.freeze
WORK_SHEET_NAME = '参加'.freeze
KODAIRA_DOJO_ID = 13

def col_index(str)
  col = 0
  str.upcase.each_byte do |b|
    col = col * 26 + (b - 0x41) # 0x41: 'A'
  end
  col
end

if ARGV.empty?
  puts 'Usage: bin/rails r scripts/kodaira_ss.rb CONFIG_JSON_FILE'
  puts
  puts 'Require the json file of configurations for Google API'
  puts 'see: https://github.com/gimite/google-drive-ruby/blob/bc8d27b1c4f7369bba6e308525377444c3932364/doc/authorization.md#on-behalf-of-you-command-line-authorization'
  exit 1
end

puts 'CoderDojo小平の統計情報スプレッドシートを解析します'

conf = File.expand_path(ARGV[0])
session = GoogleDrive::Session.from_config(conf)
ss = session.spreadsheet_by_key(SPREAD_SHEET_KEY)
ws = ss.worksheets.find { |s| s.title == WORK_SHEET_NAME }

# A:通番, C:日付, G:時間, K:合計参加者
res = ws.rows.each.with_object([]) do |row, arr|
  serial_number = Integer(row[col_index('A')]) rescue nil
  next unless serial_number
  next unless arr.length == serial_number - 1

  arr << {
    'dojo_id' => KODAIRA_DOJO_ID,
    'evented_at' => "#{row[col_index('C')]} #{row[col_index('G')].split('-').first}",
    'participants' => row[col_index('K')].to_i
  }
end

output = File.open("tmp/kodaira_histories_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.yml", 'w')
YAML.dump(res, output)

puts "#{output.path}にCoderDojo小平のEventHistoryのデータソースを書き出しました"
