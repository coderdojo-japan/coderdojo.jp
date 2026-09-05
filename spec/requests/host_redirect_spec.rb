require 'rails_helper'
require Rails.root.join('lib/rack/safe_host_redirect').to_s

# www から apex へのリダイレクトが、パスの内容で落ちないことを確認する。
#
# == 経緯（2026/09/05）==
# Airbrake に URI::InvalidURIError が届いた。
#
#   bad URI (is not URI?): "https://www.coderdojo.jp/_next/static/chunks/webpack-[hash]%2ejs"
#
# rack-host-redirect の update_url が URI() を rescue せずに呼んでおり、
# RFC3986 で許されない文字（角括弧など）がパスにあると例外になる。
# 本番で実測した挙動:
#
#   www.coderdojo.jp/foo[bar]   500  ← リダイレクトの手前で落ちる
#   coderdojo.jp/foo[bar]       404  ← apex は正常
#   www.coderdojo.jp/normal.js  301  ← 通常の www は正常
#   www.coderdojo.jp/?a[]=1     301  ← クエリの角括弧は影響しない
#
# ミドルウェアは production / staging でしか読み込まれないため、
# リクエストスペックでは経路に載らない。ここでは直接組み立てて確認する。
RSpec.describe 'www から apex へのリダイレクト' do
  MAPPING = { %w[coderdojo-japan.herokuapp.com www.coderdojo.jp] => 'coderdojo.jp' }.freeze

  # 後段のアプリは 404 を返すだけのものに差し替える。
  # リダイレクトされなかった時に、例外ではなく通常の応答になることを見たい。
  let(:downstream) { ->(_env) { [404, { 'content-type' => 'text/plain' }, ['not found']] } }
  let(:stack)      { Rack::SafeHostRedirect.new(downstream, MAPPING) }

  # Rack::MockRequest は URL を URI で解析するため、角括弧を含む要求を組めない。
  # 本番では Puma がリクエスト行から env を直接組み立てるので、そちらに合わせる。
  Response = Struct.new(:status, :headers)

  def get(host, fullpath)
    path, query = fullpath.split('?', 2)
    status, headers, = stack.call(
      'REQUEST_METHOD'  => 'GET',
      'rack.url_scheme' => 'https',
      'HTTP_HOST'       => host,
      'SERVER_NAME'     => host,
      'SERVER_PORT'     => '443',
      'PATH_INFO'       => path,
      'QUERY_STRING'    => query.to_s,
      'rack.input'      => StringIO.new
    )
    Response.new(status, headers)
  end

  describe '通常のパス' do
    it 'www を apex へ 301 で送る' do
      res = get('www.coderdojo.jp', '/kata')
      expect(res.status).to eq 301
      # Rack 3 はヘッダ名を小文字で持つ
      expect(res.headers['location']).to eq 'https://coderdojo.jp/kata'
    end

    it 'apex はそのまま通す' do
      expect(get('coderdojo.jp', '/kata').status).to eq 404
    end
  end

  describe 'RFC3986 で許されない文字を含むパス' do
    # 実際に届いたもの（Next.js のテンプレートが展開されないまま参照された形）
    it '角括弧を含んでも 500 にしない' do
      res = get('www.coderdojo.jp', '/_next/static/chunks/webpack-[hash].js')
      expect(res.status).not_to eq 500
    end

    it '角括弧だけのパスでも 500 にしない' do
      expect(get('www.coderdojo.jp', '/foo[bar]').status).not_to eq 500
    end
  end
end
