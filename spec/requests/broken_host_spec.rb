require 'rails_helper'

# Host ヘッダに非 ASCII のバイト列が入ると、ページ全体が 500 になっていた。
#
#   ActionView::Template::Error: incompatible character encodings: UTF-8 and BINARY
#     app/views/layouts/application.html.erb:21   ← og:url
#
# Puma が env に入れる HTTP_HOST は ASCII-8BIT で、request.url や *_url ヘルパーは
# そのエンコーディングを引き継ぐ。UTF-8 のビューに結合すると落ちる。
#
# 本番は config.hosts で不正な Host を 403 にする。この spec は test 環境
# (config.hosts が空) で動くので、その手前の防御が効いていることを見る。
#
# == 1 ページだけ見ても足りない ==
# 最初は /kata だけを検査していた。Host を含む値の入口は複数あり、
# /kata が通っても他のページは落ちたままだった（8 ページ中 7 ページ）。
#
#   request.url を直接使う        /kata
#   @url = request.url を渡す      /docs /news /events /podcasts
#   *_url ヘルパーを使う           /dojos /stats /dojos/activity
#
# 経路ごとに 1 本ずつ置く。
RSpec.describe 'Host ヘッダが壊れているリクエスト', type: :request do
  BROKEN_HOST = "coderdojo.jp\xFF".dup.force_encoding(Encoding::ASCII_8BIT)

  describe 'HTML ページ' do
    %w[
      /kata
      /docs
      /news
      /events
      /podcasts
      /dojos
      /stats
      /dojos/activity
    ].each do |path|
      it "#{path} が 500 にならない" do
        get path, headers: { 'HTTP_HOST' => BROKEN_HOST }

        expect(response.status).not_to eq 500
      end
    end
  end

  # ロゴの絶対 URL を root_url から組み立てている
  it '/dojos.json が 500 にならない' do
    get '/dojos.json', headers: { 'HTTP_HOST' => BROKEN_HOST }

    expect(response.status).not_to eq 500
  end

  # Rails は X-Forwarded-Host を無条件に採用するので、Host と同じ入口になる
  it 'X-Forwarded-Host 経由でも 500 にならない' do
    get '/docs', headers: { 'HTTP_X_FORWARDED_HOST' => BROKEN_HOST }

    expect(response.status).not_to eq 500
  end

  it '通常のリクエストは変わらず 200' do
    get '/kata'

    expect(response.status).to eq 200
  end
end
