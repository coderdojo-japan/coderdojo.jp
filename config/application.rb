require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CoderdojoJp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # パフォーマンス最適化: autoloadパスを$LOAD_PATHに追加しない
    config.add_autoload_paths_to_load_path = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

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

    # セキュリティヘッダーの設定
    config.action_dispatch.default_headers = {
      "X-Frame-Options" => "SAMEORIGIN",
      "X-XSS-Protection" => "0",
      "X-Content-Type-Options" => "nosniff",
      "X-Permitted-Cross-Domain-Policies" => "none",
      "Referrer-Policy" => "strict-origin-when-cross-origin"
    }

    # HTML5サニタイザーの使用
    config.action_view.sanitizer_vendor = Rails::HTML::Sanitizer.best_supported_vendor
  end
end
