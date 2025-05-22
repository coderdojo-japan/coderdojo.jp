source 'https://rubygems.org'
ruby file: '.ruby-version'

gem 'bootsnap'
gem 'pg'
gem 'puma'
gem 'puma_worker_killer'
gem 'rails', '~> 7.1.5'

gem 'jbuilder'
gem 'jquery-rails'

gem 'bootstrap-sass'
gem 'font-awesome-rails'
gem 'rails-html-sanitizer'
gem 'sass-rails', '>= 5'
gem 'simple_grid_rails'
gem 'uglifier'
gem 'concurrent-ruby'

# Add bundled gems for Ruby 3.3+
# https://gihyo.jp/article/2024/01/ruby3.3-bundled-gems
gem 'csv'
gem 'ostruct'


# For handling error by Rambulance: https://github.com/yuki24/rambulance
# FIXME: Using patch gem due to NameError: uninitialized constant ApplicationHelper
# https://github.com/coderdojo-japan/coderdojo.jp/pull/1631#issuecomment-2424826474
gem 'rambulance', git: 'https://github.com/yasslab/rambulance'

gem 'airbrake'           # Error Monitoring by Airbrake: https://github.com/airbrake/airbrake
gem 'rack-host-redirect' # For redirection
gem 'secure_headers'     # For SSL and CORS
gem 'rinku'              # For Auto Link
gem 'sitemap_generator'  # For Sitemap: https://github.com/kjvarga/sitemap_generator

gem 'rss'                # Add RSS for Podcasts: https://coderdojo.jp/podcasts
gem 'ruby-mp3info', require: 'mp3info' # For RSS feed

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

# For Pokemon image file downloads
gem 'aws-sdk-s3', '~> 1'

# Following warning are displayed and for prevention
# warning: already initialized constant Net::ProtocRetryError
# https://github.com/ruby/net-imap/issues/16
gem 'net-http'
gem 'uri'

group :development do
  gem 'flamegraph',         require: false
  gem 'memory_profiler',    require: false
  gem 'rack-mini-profiler', require: false
  gem 'stackprof',          require: false
  gem 'letter_opener_web'
  gem 'listen'
  gem 'solargraph'
  gem 'spring'
  gem 'web-console'
end

group :development, :test do
  gem 'rake'
  gem 'rspec-rails', '~> 6.1.1'
  gem 'rspec-retry'

  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'selenium-webdriver'

  gem 'rails-controller-testing'
  gem 'dotenv-rails'

  # NOTE: This enable GitHub Codespaces. Uncomment for YAGNI.
  # https://github.com/coderdojo-japan/coderdojo.jp/pull/1526
  #gem 'mini_racer'
end
