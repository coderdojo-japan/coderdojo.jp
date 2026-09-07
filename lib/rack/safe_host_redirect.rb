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
  # （Host が壊れていても応答は返る。このアプリは config.hosts を設定しておらず、
  #   Host の検証は元から行っていない。検証したいなら別の手当てが要る）
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
