require_relative '../statistics.rb'

namespace :statistics do
  desc '月次のイベント履歴を集計します'
  task :aggregation, [:from, :to] => :environment do |tasks, args|
    date_from_str = -> (str) {
      formats = %w(%Y%m %Y/%m %Y-%m)
      d = formats.map { |fmt|
        begin
          Time.zone.strptime(str, fmt)
        rescue ArgumentError
          Time.zone.local(str) if str.length == 4
        end
      }.compact.first
      raise ArgumentError, "Invalid format: `#{str}`, allow format is #{formats.push('%Y').join(' or ')}" if d.nil?
      d
    }

    from = if args[:from]
             if args[:from].length == 4
               date_from_str.call(args[:from]).beginning_of_year
             else
               date_from_str.call(args[:from]).beginning_of_month
             end
           else
             Time.current.prev_month.beginning_of_month
           end
    to = if args[:to]
           if args[:to].length == 4
             date_from_str.call(args[:to]).end_of_year
           else
             date_from_str.call(args[:to]).end_of_month
           end
         else
           Time.current.prev_month.end_of_month
         end

    EventHistory.where(evented_at: from..to).delete_all

    loop.with_object([from]) { |_, list|
      nm = list.last.next_month
      raise StopIteration if nm > to
      list << nm
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
