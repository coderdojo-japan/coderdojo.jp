# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

namespace :sitemap do
  desc 'Generate sitemap before assets:precompile'
  task :build do
    system 'bundle exec rails sitemap:refresh && gzip -dk public/sitemap.xml.gz'
  end
end
Rake::Task['assets:precompile'].enhance ['sitemap:build']

Rails.application.load_tasks
