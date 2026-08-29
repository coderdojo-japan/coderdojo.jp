Rails.application.config.middleware.use Rack::Attack

# wp-login への攻撃は意図が明確なので、その IP を 24 時間締め出す。
Rack::Attack.blocklist('fail2ban pentesters') do |req|
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", :maxretry => 1, :findtime => 1.hour, :bantime => 24.hours) do
    req.path.include?('wp-login') ||
      req.params.values.include?('wp-login')
  end
end

# .php への探索を、ルーティングより前で遮断する。
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
# ただし上の Fail2Ban には含めない。1 度踏んだだけで IP ごと 24 時間締め出す
# ため、古いリンクやブックマークで .php を踏んだ利用者まで、サイト全体から
# 締め出してしまう。wp-login と違い .php は誤って踏む範囲が広い。
# 該当のリクエストだけを拒否し、その利用者の他のアクセスは通す。
#
# 遮断がルーティングより前で効くため、コントローラに届かず Airbrake への
# 通知も発生しない。
Rack::Attack.blocklist('php probes') do |req|
  req.path.end_with?('.php')
end
