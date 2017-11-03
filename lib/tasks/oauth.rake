namespace :oauth do
  desc 'Facebookのaccess tokenを取得します'
  task :facebook_access_token, [:app_id, :app_secret] => :environment do |_tasks, args|
    puts 'Access Token: ' + Koala::Facebook::OAuth.new(args[:app_id], args[:app_secret]).get_app_access_token
  end
end
