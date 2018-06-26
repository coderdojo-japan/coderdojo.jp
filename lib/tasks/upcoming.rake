require_relative '../upcoming.rb'

namespace :upcoming do
  desc '月次のイベント開催予定を集計します'
  task :aggregation, [:from, :to] => :environment do |tasks, args|
    EventService::Providers::Facebook.access_token = Koala::Facebook::OAuth.new(ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']).get_app_access_token
    Upcoming::Aggregation.new(args).run
  end
end
