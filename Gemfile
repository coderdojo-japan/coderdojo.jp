source 'https://rubygems.org'
ruby '2.4.0'

gem 'rails',    '~> 5.0'

gem 'scrivito'
gem 'scrivito_section_widgets'
gem 'scrivito_teaser_widget'

gem 'coffee-rails'
gem 'jbuilder'
gem 'jquery-rails'

gem 'simple_grid_rails'
gem "bootstrap-sass"
gem 'sass-rails'
gem 'uglifier'
gem 'font-awesome-rails'

# For SSL and CORS
gem 'secure_headers'

# Rendering legal documents
gem 'kramdown'

# TODO: Delete this if the following issue is fixed
# https://github.com/bundler/bundler/issues/5332
gem 'faraday_middleware', '0.10'

group :development do
  gem 'web-console'
  gem 'spring'
  gem 'rspec-rails'
end

group :development, :test do
  gem 'sqlite3'
  gem 'pry-rails'
  gem 'rake'
  gem 'travis'
  gem 'minitest-retry'
end

group :test do
  gem 'rails-controller-testing'
end

group :production do
  gem 'pg'
end
