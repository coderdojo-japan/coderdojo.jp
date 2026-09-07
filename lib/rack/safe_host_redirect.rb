require 'rack/host_redirect'

module Rack
  # www から apex へのリダイレクトが、パスの内容で 500 にならないようにする。
  #
  # rack-host-redirect の update_url は URI() を rescue せずに呼ぶため、
  # RFC3986 で許されない文字（角括弧など）がパスにあると例外になり、
  # リダイレクトを組み立てる手前で 500 が返る。2026年9月5日に本番で観測した。
  #
  # 組み立てられないものは、リダイレクトせず後段へ渡す。ルーティングに
  # 一致しないので 404 になる。apex 側の同じパスと同じ扱いになる。
  #
  #   www.coderdojo.jp/foo[bar]   500 → 404
  #   coderdojo.jp/foo[bar]       404（元から）
  #   www.coderdojo.jp/kata       301（変わらない）
  #
  # rescue で super を包まない。super には「リダイレクトしない場合の
  # @app.call(env)」も含まれるため、後段が同じ例外を投げると後段を 2 回呼ぶ。
  # POST の副作用や Rack::Attack のカウンタが二重になる。
  # 先に URI() の可否だけを見て、後段の例外はそのまま通す。
  class SafeHostRedirect < HostRedirect
    def call(env)
      begin
        # gem が update_url で行う解析と同じもの
        URI(Rack::Request.new(env).url)
      rescue URI::InvalidURIError
        return @app.call(env)
      end

      super
    end
  end
end
