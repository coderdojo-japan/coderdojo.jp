require_relative '../upcoming_events.rb'

namespace :upcoming_events do
  desc '指定期間/プロバイダのイベント履歴を集計します'
  task :aggregation, [:provider] => :environment do |tasks, args|
    UpcomingEvent.transaction do
      UpcomingEvents::Aggregation.new(args).run
    end
  end
end
