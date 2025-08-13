#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

# 統計ページの累積合計データ（/statsから取得）
# これはsum(:counter)の値（支部数の合計）
STATS_COUNTER_TOTALS = {
  2012 => 5,
  2013 => 7,
  2014 => 17,
  2015 => 22,
  2016 => 63,
  2017 => 118,
  2018 => 172,
  2019 => 200,
  2020 => 222,
  2021 => 236,
  2022 => 225,
  2023 => 199,
  2024 => 206
}

BASE_URL = 'http://localhost:3000'

def fetch_dojos_count(year)
  uri = URI("#{BASE_URL}/dojos.json?year=#{year}")
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    JSON.parse(response.body).length
  else
    nil
  end
end

def test_invalid_years
  puts "\n📍 無効な年のテスト:"
  
  # 範囲外の年
  [2011, 2026].each do |year|
    uri = URI("#{BASE_URL}/dojos.json?year=#{year}")
    response = Net::HTTP.get_response(uri)
    
    # HTMLページへのリダイレクトを期待（302 Found）
    if response.code == '302' || response.code == '303'
      puts "  ✅ #{year}年: リダイレクト (#{response.code})"
    else
      puts "  ❌ #{year}年: 予期しないレスポンス (#{response.code})"
    end
  end
  
  # 文字列の年
  uri = URI("#{BASE_URL}/dojos.json?year=invalid")
  response = Net::HTTP.get_response(uri)
  if response.code == '302' || response.code == '303'
    puts "  ✅ 'invalid': リダイレクト (#{response.code})"
  else
    puts "  ❌ 'invalid': 予期しないレスポンス (#{response.code})"
  end
end

def main
  puts "🧪 道場数年次フィルタリングのテスト"
  puts "=" * 50
  
  all_passed = true
  
  puts "\n📊 各年のアクティブ道場数の検証:"
  puts "※ /dojos は道場リスト（道場数）、/stats は支部数合計（counter合計）を返します"
  puts "\n年    | /stats | /dojos | 差分  | 説明"
  puts "-" * 50
  
  STATS_COUNTER_TOTALS.each do |year, stats_total|
    dojos_count = fetch_dojos_count(year)
    
    if dojos_count.nil?
      puts "#{year} | #{stats_total.to_s.rjust(6)} | ERROR  |       | ❌ 取得失敗"
      all_passed = false
    else
      diff = stats_total - dojos_count
      status = diff >= 0 ? "✅" : "❌"
      puts "#{year} | #{stats_total.to_s.rjust(6)} | #{dojos_count.to_s.rjust(6)} | #{diff.to_s.rjust(5)} | #{status} #{diff > 0 ? "複数支部あり" : ""}"
    end
  end
  
  # 無効な年のテスト
  test_invalid_years
  
  # yearパラメータなしの場合
  puts "\n📍 yearパラメータなしのテスト:"
  uri = URI("#{BASE_URL}/dojos.json")
  response = Net::HTTP.get_response(uri)
  if response.code == '200'
    total_count = JSON.parse(response.body).length
    puts "  全道場数: #{total_count}個"
    
    # 全道場数は2024年の道場数よりも多いはず（非アクティブ含むため）
    dojos_2024 = fetch_dojos_count(2024)
    if total_count >= dojos_2024
      puts "  ✅ 全道場数(#{total_count}) >= 2024年アクティブ道場数(#{dojos_2024})"
    else
      puts "  ❌ データ不整合: 全道場数が2024年アクティブ数より少ない"
      all_passed = false
    end
  else
    puts "  ❌ 取得失敗"
    all_passed = false
  end
  
  puts "\n" + "=" * 50
  if all_passed
    puts "✅ すべてのテストが成功しました！"
  else
    puts "❌ 一部のテストが失敗しました"
    exit 1
  end
end

main if __FILE__ == $0