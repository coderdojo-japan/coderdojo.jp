Rails.application.config.middleware.use Rack::Attack

# 攻撃的な探索を、ルーティングより前で遮断する。
#
# 2026/08/29 に本番ログで .php へのアクセスを 94 件観測した（2 つの IP に集中）。
# 認証情報や設定ファイルの探索、Web シェル設置の試行が含まれていた。
#
#   /aws_sdk_settings.php    /application.config.php   /php_info.php
#   /wp-admin/sc.php         /a1vx.php /lmfi2.php /koiy.php
#
# wp-login だけを見ていたため /wp-admin/sc.php はすり抜けていた。
# このアプリに .php は 1 つも無い（routes・public とも 0 件）ので、
# .php へのアクセスに正当なものは存在しない。
#
# 遮断がルーティングより前で効くため、コントローラに届かず Airbrake への
# 通知も止まる。通知側でフィルタする必要はない。
Rack::Attack.blocklist('fail2ban pentesters') do |req|
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", :maxretry => 1, :findtime => 1.hour, :bantime => 24.hours) do
    req.path.include?('wp-login') ||
      req.params.values.include?('wp-login') ||
      req.path.end_with?('.php')
  end
end
