source 'https://rubygems.org'
ruby '2.7.7'

gem 'rails', '~> 6.0'
gem 'puma'
gem "puma_worker_killer"
gem 'pg'
gem 'dumper', git: 'https://github.com/yasslab/dumper' # For database backup
gem 'bootsnap'

gem 'coffee-rails'
gem 'jbuilder'
gem 'jquery-rails'

gem 'simple_grid_rails'
gem "bootstrap-sass"
gem 'sass-rails', '>= 5'
gem 'uglifier'
gem 'font-awesome-rails'
gem 'haml-rails'
gem 'rails-html-sanitizer', '~> 1.4.4'

# For redirection
gem 'rack-host-redirect'

# For SSL and CORS
gem 'secure_headers'

# Rendering legal documents
gem 'kramdown'
gem 'kramdown-parser-gfm'

gem 'faraday'
gem 'faraday_middleware'

gem 'koala'
gem 'rack-user_agent'
gem 'rack-attack'
gem 'google_drive'
gem 'lazy_high_charts', "1.5.8"

# For RSS feed
gem 'ruby-mp3info', :require => 'mp3info'

# For Sitemap (Google Search Console)
gem 'sitemap_generator'

# For Pokemon image file downloads
gem 'aws-sdk-s3', '~> 1'

# Following warning are displayed and for prevention
# warning: already initialized constant Net::ProtocRetryError
# https://github.com/ruby/net-imap/issues/16
gem 'net-http'
gem 'uri', '0.10.0'

group :development do
  gem 'web-console'
  gem 'spring'
  gem 'listen'
  gem 'letter_opener_web'
  gem 'stackprof',  require: false
  gem 'flamegraph', require: false
  gem 'memory_profiler',    require: false
  gem 'rack-mini-profiler', require: false
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  gem 'rake'
  gem 'minitest-retry'
  gem 'rspec-retry'

  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'rspec-rails', '~> 4.0'
  gem 'factory_bot_rails'

  gem 'dotenv-rails'
end

group :test do
  gem 'rails-controller-testing'
end
