require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoderdojoJp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Timezone
    config.time_zone = 'Asia/Tokyo'

    # Default I18n locale
    config.i18n.default_locale = :ja

    # Fixture paths
    config.fixture_paths = [Rails.root.join('spec/fixtures')]

    # HTML と JSON を gzip して返す。Heroku のルーターは応答を圧縮しない。
    # assets は gzip 済みのファイルを ActionDispatch::Static が返すので、対象は HTML と JSON に絞る。
    # Static は public_file_server が無効な環境では積まれないため、どの環境にもある Rack::Sendfile の後ろに置く。
    # Rack::ETag より外側に置くこと。内側だと gzip の時刻が入った本文で ETag を計算し、304 が返らなくなる
    config.middleware.insert_after Rack::Sendfile, Rack::Deflater, include: %w[text/html application/json]
  end
end
