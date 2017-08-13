require_relative '../statistics.rb'

namespace :statistics do
  desc '月次のイベント履歴を集計します'
  task :aggregation, [:yyyymm] => :environment do |tasks, args|
    date = Time.current.prev_month.beginning_of_month
    if args[:yyyymm].present?
      date = %w(%Y%m %Y/%m %Y-%m).map do |fmt|
               begin
                 Time.zone.strptime(args[:yyyymm], fmt)
               rescue ArgumentError
               end
             end.compact.first
    end

    raise ArgumentError, "Invalid format: #{args[:yyyymm]}" if date.nil?


    EventHistory.where(evented_at: date.beginning_of_month..date.end_of_month).delete_all

    Statistics::Aggregation.run(date: date)
  end

  task :search, [:keyword] => :environment do |tasks, args|
    raise ArgumentError, 'Require the keyword' if args[:keyword].nil?

    require 'pp'

    puts 'Searching Connpass'
    pp Statistics::Client::Connpass.new.search(keyword: args[:keyword])

    puts 'Searching Doorkeeper'
    pp Statistics::Client::Doorkeeper.new.search(keyword: args[:keyword])
  end
end
