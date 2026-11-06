# Airbrake と並べて、エラーを Sentry にも送る。DSN は環境変数 SENTRY_DSN から読み、無ければ何も送らない。
# 2 週間ほど並べて件数を比べ、Sentry に寄せられそうなら Airbrake を外す
Sentry.init do |config|
  config.dsn                             = ENV['SENTRY_DSN']
  config.enabled_environments            = %w[production]
  # rescue で捕まえて Rails.error.report した例外も送る（Airbrake は AirbrakeErrorSubscriber で受けている）
  config.rails.register_error_subscriber = true
  # traces_sample_rate は書かない。0.0 でも計測の仕組みが動き、全リクエストで記録を作る（送らないだけ）
  # 404・UnknownFormat・InvalidType などは sentry-rails の既定で送らない。Airbrake には届くので、件数は Sentry の方が少なく出る
end
