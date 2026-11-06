# Airbrake と並べて、エラーを Sentry にも送る。DSN は環境変数 SENTRY_DSN から読み、無ければ何も送らない。
# 2 週間ほど並べて件数を比べ、Sentry に寄せられそうなら Airbrake を外す
Sentry.init do |config|
  config.dsn                             = ENV['SENTRY_DSN']
  config.enabled_environments            = %w[production]
  # rescue で捕まえて Rails.error.report した例外も送る（Airbrake は AirbrakeErrorSubscriber で受けている）
  config.rails.register_error_subscriber = true
  config.traces_sample_rate              = 0.0
  config.excluded_exceptions            += %w[ActiveRecord::RecordNotFound ActionController::RoutingError]
end
