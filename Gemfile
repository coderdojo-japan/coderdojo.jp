source 'https://rubygems.org'
ruby '3.1.6'

gem 'bootsnap'
gem 'pg'
gem 'puma'
gem 'puma_worker_killer'
gem 'rails', '~> 7.0'

gem 'coffee-rails'
gem 'jbuilder'
gem 'jquery-rails'

gem 'bootstrap-sass'
gem 'font-awesome-rails'
gem 'haml-rails'
gem 'rails-html-sanitizer', '~> 1.4.4'
gem 'sass-rails', '>= 5'
gem 'simple_grid_rails'
gem 'uglifier'

# Specify to 1.3.4 to prevent error
# TODO: This can be removed on Rails 7.1
# https://github.com/rails/rails/issues/54260
# https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
gem 'concurrent-ruby', '1.3.4'

# For handling error
# https://github.com/yuki24/rambulance
# Using patch gem due to NameError: uninitialized constant ApplicationHelper
# https://github.com/coderdojo-japan/coderdojo.jp/pull/1631#issuecomment-2424826474
gem 'rambulance', git: 'https://github.com/yasslab/rambulance'

# For redirection
gem 'rack-host-redirect'

# Add RSS for podcasts
gem 'rss'

# For SSL and CORS
gem 'secure_headers'

# Rendering legal documents
gem 'kramdown'
gem 'kramdown-parser-gfm'

gem 'faraday'
gem 'faraday_middleware'

gem 'google_drive'
gem 'koala'
gem 'lazy_high_charts', '1.5.8'
gem 'rack-attack'
gem 'rack-user_agent'

# For Auto Link
gem 'rinku'

# For RSS feed
gem 'ruby-mp3info', require: 'mp3info'

# For Sitemap (Google Search Console)
gem 'sitemap_generator'

# For Pokemon image file downloads
gem 'aws-sdk-s3', '~> 1'

# Following warning are displayed and for prevention
# warning: already initialized constant Net::ProtocRetryError
# https://github.com/ruby/net-imap/issues/16
gem 'net-http'
gem 'uri'

group :development do
  gem 'flamegraph', require: false
  gem 'letter_opener_web'
  gem 'listen'
  gem 'memory_profiler', require: false
  gem 'rack-mini-profiler', require: false
  gem 'solargraph'
  gem 'spring'
  gem 'stackprof', require: false
  gem 'web-console'
end

group :development, :test do
  gem 'minitest-retry'
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
  gem 'rake'
  gem 'rspec-retry'

  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 4.0'
  gem 'selenium-webdriver'

  gem 'dotenv-rails'
end

group :test do
  gem 'rails-controller-testing'
end

# Enable to edit on GitHub Codespaces
# https://github.com/coderdojo-japan/coderdojo.jp/pull/1526
gem 'mini_racer'
