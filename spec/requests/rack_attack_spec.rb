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
  # test 環境のキャッシュは null_store で、Fail2Ban の BAN が保存されない。
  # 本番は memory_store なので、そのままでは本番と違う経路を検証してしまう。
  before do
    @original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
    Rack::Attack.cache.store = @original_store
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

  # .php を Fail2Ban に含めると、1 回踏んだだけで IP ごと 24 時間締め出される。
  # 攻撃者には妥当だが、古いリンクやブックマークで .php を踏んだ利用者まで
  # サイト全体から締め出してしまう。wp-login と違い .php は誤って踏む範囲が広い。
  #
  # 実際、この挙動で開発者自身の IP が本番から締め出された（2026/08/29）。
  describe '.php を踏んでも他のアクセスは遮断しない' do
    let(:ip) { '203.0.113.10' }

    it '.php を繰り返しても通常のページを見られる' do
      3.times { get '/news.php', env: { 'REMOTE_ADDR' => ip } }
      expect(response).to have_http_status(:forbidden)

      get '/', env: { 'REMOTE_ADDR' => ip }
      expect(response).not_to have_http_status(:forbidden)
    end
  end

  # wp-login は攻撃の意図が明確なので、これまでどおり IP を BAN する
  describe 'wp-login を踏んだ IP は締め出す' do
    let(:ip) { '203.0.113.11' }

    # maxretry: 1 は「2 回目で BAN」を意味する（1 回目でカウントが 1 になる）
    it 'wp-login を繰り返すと通常のページも遮断される' do
      2.times { get '/wp-login', env: { 'REMOTE_ADDR' => ip } }

      get '/', env: { 'REMOTE_ADDR' => ip }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
