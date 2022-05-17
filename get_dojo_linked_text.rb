#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'pry'

uri      = URI.parse('https://coderdojo.jp/dojos.json')
dojos    = JSON.parse(Net::HTTP.get uri)
result   = "<ul>\n"
#pp dojos
#binding.pry

# TODO: スプレッドシートの入力列（コピペ）と、
#       API 取得結果を突き合わせる処理を追加する。
dojos.sample(5).each do |d|
  result << "  <li>#{d['linked_text']}</li>\n"
end
result << "</ul>\n"

puts result
