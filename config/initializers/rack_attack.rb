Rails.application.config.middleware.use Rack::Attack

# 送信元 IP は X-Forwarded-For だけから判定する。
#
# Rack 3 の既定では Forwarded ヘッダ (RFC 7239) を X-Forwarded-For より優先する。
# Heroku のルータが追記するのは X-Forwarded-For だけなので、クライアントが
# Forwarded を付けると送信元 IP を偽装でき、下の IP 単位の遮断をすり抜けられる。
Rack::Request.forwarded_priority = [:x_forwarded]

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

# JPCERT/CC の注意喚起 (JPCERT-AT-2026-0030) で、国内組織への不正アクセスの
# 送信元として報告された IP を遮断する（2026/10/08 公開）。
# https://www.jpcert.or.jp/at/2026/at260030.html
#
# 3.112.252.14 と 54.95.112.6 は AWS 東京リージョンのアドレスで、今後ほかの
# 利用者に割り当て直される可能性がある。2027/01 を目安に、外すか見直す。
JPCERT_REPORTED_IPS = %w[
  3.112.252.14
  54.95.112.6
  69.10.51.162
  172.86.91.7
  210.149.87.120
  213.163.202.171
  221.216.140.49
  221.216.140.129
].to_set.freeze

Rack::Attack.blocklist('jpcert reported ips') do |req|
  JPCERT_REPORTED_IPS.include?(req.ip)
end

# POST /stretch3 は、このサイトで唯一の書き込みエンドポイント。
# JPCERT/CC の注意喚起 (JPCERT-AT-2026-0030) の推奨に沿い、送信元 IP ごとに回数を制限する。
# 1 つの Dojo で 20〜30 人が同じ回線から送信しても届かない上限にしている。
#
# Rails の rate_limit ではなく Rack::Attack を使うのは、上の遮断と同じく
# ルーティングより前で 429 を返し、Airbrake への通知が発生しないため。
# start_with? にしているのは /stretch3.json などの表記ゆれも同じルートに届くため。
Rack::Attack.throttle('stretch3 form', limit: 60, period: 1.hour) do |req|
  req.ip if req.post? && req.path.start_with?('/stretch3')
end
