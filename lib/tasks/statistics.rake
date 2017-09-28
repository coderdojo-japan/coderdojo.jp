require_relative '../statistics.rb'

namespace :statistics do
  desc '月次のイベント履歴を集計します'
  task :aggregation, [:from_yyyymm, :to_yyyymm] => :environment do |tasks, args|
    date_from_str = -> (str) {
      d = %w(%Y%m %Y/%m %Y-%m).map { |fmt|
        begin
          Time.zone.strptime(str, fmt)
        rescue ArgumentError
        end
      }.compact.first
      raise ArgumentError, "Invalid format: `#{str}`" if d.nil?
      d
    }

    from = (args[:from_yyyymm] ? date_from_str.call(args[:from_yyyymm]) : Time.current.prev_month).beginning_of_month
    to   = (args[:to_yyyymm]   ? date_from_str.call(args[:to_yyyymm])   : Time.current.prev_month).end_of_month

    EventHistory.where(evented_at: from..to).delete_all

    loop.with_object([from]) { |_, list|
      nm = list.last.next_month
      nm > to ? (break list) : (list << nm)
    }.each { |date|
      Statistics::Aggregation.run(date: date)
    }
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
