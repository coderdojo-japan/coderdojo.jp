require_relative '../statistics.rb'

namespace :statistics do
  desc '指定期間/プロバイダのイベント履歴を集計します'
  task :aggregation, [:from, :to, :provider, :dojo_id] => :environment do |tasks, args|
    EventHistory.transaction do
      Statistics::Aggregation.new(args).run
    end
  end

  desc '集計が静かに壊れていないかを確認します（直近 N 日で 0 件のプロバイダを検知）'
  task :sanity_check, [:days] => :environment do |tasks, args|
    days = args[:days].presence&.to_i || 30
    Statistics::SanityCheck.new(days: days).run
  end

  desc 'キーワードからイベント情報を検索します'
  task :search, [:keyword] => :environment do |tasks, args|
    raise ArgumentError, 'Require the keyword' if args[:keyword].nil?

    require 'pp'

    puts 'Searching Connpass'
    pp EventService::Providers::Connpass.new.search(keyword: args[:keyword])

    puts 'Searching Doorkeeper'
    pp EventService::Providers::Doorkeeper.new.search(keyword: args[:keyword])
  end
end
