require_relative '../statistics.rb'

namespace :statistics do
  desc '月次/週次のイベント履歴を集計します'
  task :aggregation, [:from, :to] => :environment do |tasks, args|
    Statistics::Providers::Facebook.access_token = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']).get_app_access_token
    Statistics::Aggregation.new(args).run
  end

  desc 'キーワードからイベント情報を検索します'
  task :search, [:keyword] => :environment do |tasks, args|
    raise ArgumentError, 'Require the keyword' if args[:keyword].nil?

    require 'pp'

    puts 'Searching Connpass'
    pp Statistics::Client::Connpass.new.search(keyword: args[:keyword])

    puts 'Searching Doorkeeper'
    pp Statistics::Client::Doorkeeper.new.search(keyword: args[:keyword])
  end
end
