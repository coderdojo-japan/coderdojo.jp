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

    Statistics::Aggregation.run(date: date)
  end
end
