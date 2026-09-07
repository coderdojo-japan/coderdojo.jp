require "active_support/core_ext/integer/time"
# ミドルウェアは初期化時に定数を解決するため、autoload では間に合わない
require_relative "../../lib/rack/safe_host_redirect"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "coderdojo.jp" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Heroku に登録しているドメイン。下の 2 つの設定で同じ集合を使う。
  # ズレると www へのリダイレクトが 403 になるため、1 箇所で定義する。
  canonical_host = 'coderdojo.jp'
  alias_hosts    = %w[www.coderdojo.jp coderdojo-japan.herokuapp.com]

  # Host ヘッダを検証する。
  #
  # Heroku のルータは「登録ドメイン + `:` 以降は何でも」を通すため、
  # `Host: coderdojo.jp:abc` のような値がアプリまで届く。実際に
  # /docs/<存在しない> が 500 になっていた（2026-09-07 に本番で確認）。
  # X-Forwarded-Host も検証対象になるので、og:url に任意のホストが
  # 反映される状態も閉じる。
  #
  # 上のヘルスチェック用の除外は付けない。/up のルートが存在しないため、
  # 付けても意味のないバイパスが増えるだけになる。
  config.hosts = [canonical_host, *alias_hosts]

  # Redirect if not in correct domains
  config.middleware.use Rack::SafeHostRedirect, {
    alias_hosts => canonical_host
  }

  # Mailer settings
  config.action_mailer.delivery_method       = :smtp
  config.action_mailer.default_url_options   = { host: ENV['CODERDOJO_JAPAN_DEFAULT_URL'] }
  ActionMailer::Base.smtp_settings           = {
    address:              'smtp.mailgun.org',
    port:                 '587',
    authentication:       :plain,
    user_name:            ENV['CODERDOJO_JAPAN_MAILGUN_USER'],
    password:             ENV['CODERDOJO_JAPAN_MAILGUN_PASS'],
    domain:               'coderdojo.jp',
    enable_starttls_auto: true
  }
end
