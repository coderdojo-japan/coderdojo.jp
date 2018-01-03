require_relative '../statistics.rb'

namespace :statistics do
  desc '月次/週次のイベント履歴を集計します'
  task :aggregation, [:from, :to] => :environment do |tasks, args|
    date_from_str = -> (str) {
      formats = %w(%Y%m%d %Y/%m/%d %Y-%m-%d %Y%m %Y/%m %Y-%m)
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

    notify_idobata = -> (msg) {
      puts `curl --data-urlencode "source=#{msg}" -s #{ENV['IDOBATA_HOOK_URL']} -o /dev/null -w "idobata: %{http_code}"` if ENV.key?('IDOBATA_HOOK_URL')
    }

    ym_format = -> (date) { date.strftime('%Y/%m') }
    ymd_format = -> (date) { date.strftime('%Y/%m/%d') }

    montly_aggregation = -> (from, to) {
      loop.with_object([from]) { |_, list|
        nm = list.last.next_month
        raise StopIteration if nm > to
        list << nm
      }.each { |date|
        puts "Aggregate for #{ym_format.call(date)}"
        Statistics::Aggregation.run(date: date, weekly: false)
      }
    }

    weekly_aggregation = -> (from, to) {
      loop.with_object([from]) { |_, list|
        nw = list.last.next_week
        raise StopIteration if nw > to
        list << nw
      }.each { |date|
        puts "Aggregate for #{ymd_format.call(date)}~#{ymd_format.call(date.end_of_week)}"
        Statistics::Aggregation.run(date: date, weekly: true)
      }
    }

    weekly = true

    from = if args[:from]
             if args[:from].length == 4
               weekly = false
               date_from_str.call(args[:from]).beginning_of_year
             elsif args[:from].length == 6
               weekly = false
               date_from_str.call(args[:from]).beginning_of_month
             else
               date_from_str.call(args[:from]).beginning_of_week
             end
           else
             Time.current.prev_week.beginning_of_week
           end
    to = if args[:to]
           if args[:to].length == 4
             date_from_str.call(args[:to]).end_of_year
           elsif args[:to].length == 6
             date_from_str.call(args[:to]).end_of_month
           else
             date_from_str.call(args[:to]).end_of_week
           end
         else
           Time.current.prev_week.end_of_week
         end

    Statistics::Providers::Facebook.access_token = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']).get_app_access_token

    EventHistory.where(evented_at: from..to).delete_all

    from_str = weekly ? ym_format.call(from) : ymd_format.call(from)
    to_str = weekly ? ym_format.call(to) : ymd_format.call(to)

    begin
      if weekly
        weekly_aggregation.call(from, to)
      else
        montly_aggregation.call(from, to)
      end

      notify_idobata.call("#{from_str}~#{to_str}のイベント履歴の集計を行いました")
    rescue => e
      notify_idobata.call("#{from_str}~#{to_str}のイベント履歴の集計でエラーが発生しました\n#{e.message}")
      raise e
    end
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
