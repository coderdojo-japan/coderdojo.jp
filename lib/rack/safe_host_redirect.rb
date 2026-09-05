module Rack
  # www から apex への 301 を、URI 解析を経ずに組み立てる。
  #
  # rack-host-redirect の update_url は URI() を rescue せずに呼ぶため、
  # RFC3986 で許されない文字（角括弧など）がパスにあると URI::InvalidURIError で
  # 落ち、リダイレクトの手前で 500 になる。2026年9月5日に本番で観測した。
  #
  #   www.coderdojo.jp/foo[bar]   500 → 301（この変更後）
  #   coderdojo.jp/foo[bar]       404（apex は元から正常）
  #
  # 実際に届いていたのは、Next.js のテンプレートが展開されないまま参照された
  # `/_next/static/chunks/webpack-[hash].js` の形。このアプリに該当する資産は無い。
  #
  # ホストを差し替えるだけなら解析は要らない。scheme とホストを置き換え、
  # パスとクエリは受け取ったまま繋ぐ。
  class SafeHostRedirect
    # mapping は rack-host-redirect と同じ形を受ける。
    #   { %w[old-a.example.jp old-b.example.jp] => 'example.jp' }
    def initialize(app, mapping)
      @app = app
      @hosts = mapping.each_with_object({}) do |(from, to), h|
        Array(from).each { |f| h[f.to_s.downcase] = to.to_s.downcase }
      end
    end

    def call(env)
      request = Rack::Request.new(env)
      target  = @hosts[request.host.to_s.downcase]
      return @app.call(env) unless target

      location = "#{request.scheme}://#{target}#{request.fullpath}"
      [301,
       { 'location' => location, 'content-type' => 'text/html', 'content-length' => '0' },
       []]
    end
  end
end
