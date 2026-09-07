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
      expect(res.headers['Location']).to eq 'https://coderdojo.jp/kata'
    end

    it 'apex はそのまま通す' do
      expect(get('coderdojo.jp', '/kata').status).to eq 404
    end
  end

  # rescue の範囲。super には「リダイレクトしない場合の @app.call(env)」も
  # 含まれるので、素朴に包むと後段が投げた同じ例外まで拾い、後段をもう一度
  # 呼んでしまう。POST の副作用や Rack::Attack のカウンタが二重になる。
  describe '後段が同じ例外を投げたとき' do
    it '後段を 2 回呼ばない' do
      calls = 0
      raiser = lambda do |_env|
        calls += 1
        raise URI::InvalidURIError, 'from downstream'
      end
      stack = Rack::SafeHostRedirect.new(raiser, MAPPING)

      expect {
        stack.call(
          'REQUEST_METHOD'  => 'POST',
          'rack.url_scheme' => 'https',
          'HTTP_HOST'       => 'coderdojo.jp', # リダイレクト対象外 = 後段へ渡る
          'SERVER_NAME'     => 'coderdojo.jp',
          'SERVER_PORT'     => '443',
          'PATH_INFO'       => '/stretch3',
          'QUERY_STRING'    => '',
          'rack.input'      => StringIO.new
        )
      }.to raise_error(URI::InvalidURIError)

      expect(calls).to eq 1
    end
  end

  # gem の get_updated_uri_opts は request.host.downcase を呼ぶ。
  # Host ヘッダが壊れていると Rack::Request#host は nil を返し、NoMethodError になる。
  # URI() は通ってしまう形（末尾コロンなど）があるので、URI の可否だけでは足りない。
  describe 'Host ヘッダが壊れているとき' do
    {
      'ポートが数値でない' => 'www.coderdojo.jp:abc',
      '末尾がコロン'       => 'www.coderdojo.jp:',
      '括弧が壊れている'   => '[',
    }.each do |label, host|
      it "#{label}でも 500 にせず、後段へ渡す" do
        expect(get(host, '/kata').status).to eq 404
      end
    end
  end

  describe 'RFC3986 で許されない文字を含むパス' do
    # リダイレクト先を組み立てられないものは、後段へ渡して 404 にする。
    # apex 側の同じパスと同じ扱いになる。

    # 実際に届いたもの（Next.js のテンプレートが展開されないまま参照された形）
    it '角括弧を含んでも 500 にせず、後段へ渡す' do
      expect(get('www.coderdojo.jp', '/_next/static/chunks/webpack-[hash].js').status).to eq 404
    end

    it '角括弧だけのパスでも 500 にせず、後段へ渡す' do
      expect(get('www.coderdojo.jp', '/foo[bar]').status).to eq 404
    end
  end
end
