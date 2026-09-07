require 'rack/host_redirect'

module Rack
  # www から apex へのリダイレクトが、リクエストの内容で 500 にならないようにする。
  #
  # rack-host-redirect は次の 2 つを前提にしているが、どちらも rescue していない。
  #
  #   1. Rack::Request#host が nil でない（get_updated_uri_opts が host.downcase を呼ぶ）
  #   2. Rack::Request#url が URI() で解析できる（update_url が URI() を呼ぶ）
  #
  # 前提が崩れると、リダイレクトを組み立てる手前で例外になり 500 が返る。
  # 2026年9月に本番で両方とも観測した。
  #
  #   www.coderdojo.jp/foo[bar]        URI::InvalidURIError（パスの文字）
  #   Host: www.coderdojo.jp:          NoMethodError（host が nil。URI() は通る）
  #
  # 前提が崩れているものは、リダイレクトせず後段へ渡す。apex 宛と同じ扱いになり、
  # パスがルートに一致すればその応答を、しなければ 404 を返す。
  # 本番は config.hosts が Host と X-Forwarded-Host を検証するが、
  # Rack::Request#host はそれより優先して Forwarded ヘッダ (RFC 7239) を読む。
  # config.hosts は Forwarded を見ないので、ここに来る host が正規とは限らない。
  # 実測: Host: coderdojo.jp + Forwarded: host="www.coderdojo.jp:" で host は nil になる。
  #
  # rescue で super を包まない。super には「リダイレクトしない場合の @app.call(env)」も
  # 含まれるため、後段が同じ例外を投げると後段を 2 回呼ぶ。POST の副作用や
  # Rack::Attack のカウンタが二重になる。
  class SafeHostRedirect < HostRedirect
    def call(env)
      return @app.call(env) unless redirectable?(env)

      super
    end

    private

    def redirectable?(env)
      request = Rack::Request.new(env)
      return false if request.host.nil?

      URI(request.url)
      true
    rescue URI::InvalidURIError
      false
    end
  end
end
