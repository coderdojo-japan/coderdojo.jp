namespace :sitemap do
  desc 'Generate sitemap before assets:precompile'
  task :build do
    system 'bundle exec rails sitemap:refresh && gzip -dk public/sitemap.xml.gz'
  end
end

Rake::Task['assets:precompile'].enhance ['sitemap:build']
