require 'rails_helper'

# 攻撃的な探索を、コントローラに届く前に遮断する。
#
# == 経緯（2026/08/29）==
# Airbrake に ActionController::UnknownFormat（/news.php）の通知が来た。
# 本番ログを見ると .php へのアクセスが 94 件、2 つの IP に集中していた。
#
#   /aws_sdk_settings.php    認証情報の探索
#   /application.config.php  設定ファイルの探索
#   /php_info.php            環境情報の露出確認
#   /wp-admin/sc.php         Web シェル設置の試行
#   /a1vx.php /lmfi2.php     既知の Web シェルのファイル名
#
# 既存の遮断は wp-login だけを見ており、/wp-admin/sc.php はすり抜けていた。
# このアプリに .php は 1 つも無いため（routes・public とも 0 件）、
# .php へのアクセスに正当なものは存在しない。
#
# 遮断はルーティングより前で効くので、通知も自然に止まる。
RSpec.describe 'Rack::Attack', type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
  end

  describe '.php へのアクセス' do
    # 実際に本番ログで観測されたパス
    %w[
      /news.php
      /aws_sdk_settings.php
      /application.config.php
      /php_info.php
      /wp-admin/sc.php
      /a1vx.php
      //koiy.php
    ].each do |path|
      it "#{path} を遮断する" do
        get path, env: { 'REMOTE_ADDR' => '203.0.113.1' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '通常のアクセス' do
    %w[/ /dojos /events /news /news.json].each do |path|
      it "#{path} は遮断しない" do
        get path, env: { 'REMOTE_ADDR' => '203.0.113.2' }
        expect(response).not_to have_http_status(:forbidden)
      end
    end
  end

  # 既存の遮断（wp-login）が壊れていないこと
  it 'wp-login を遮断する' do
    get '/wp-login', env: { 'REMOTE_ADDR' => '203.0.113.3' }
    expect(response).to have_http_status(:forbidden)
  end
end
