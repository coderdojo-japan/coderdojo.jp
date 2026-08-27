require 'rails_helper'

# HTML しか返さないアクションに .json でアクセスすると 500 になっていた。
# クローラーが .json を試すたびに Airbrake へ通知が飛び、本物のエラーが埋もれる。
# 形式が合わないだけなのでサーバエラーではなく 406 を返す。
# cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1887
RSpec.describe '対応していない形式でのリクエスト', type: :request do
  # respond_to を持たない（HTML 専用の）アクション
  %w[
    /dojos/activity.json
    /docs.json
    /kata.json
    /spaces.json
  ].each do |path|
    it "#{path} は 406 を返す（500 にしない）" do
      get path
      expect(response).to have_http_status(:not_acceptable)
    end
  end

  # /podcasts/:id は show 内で render_to_string(partial:) を呼ぶ。
  # render_to_string はリクエストの形式を引き継ぐため、.jpg でアクセスされると
  # _youtube_embed.jpeg.* を探しに行き ActionView::MissingTemplate で 500 になる。
  # cf. https://github.com/coderdojo-japan/coderdojo.jp/pull/1888
  describe '/podcasts/:id' do
    # content は DB のカラムではなく public/podcasts/<id>.md を読む実装のため、
    # YouTube 埋め込みを含む実ファイルがある id を使って再現する。
    let!(:episode) { create(:podcast, id: 14) }

    # public/podcasts/<id>.png はカバー画像として実在し、静的ファイルとして
    # 配信される（本番でも 200 image/png）。ここでは扱わない。
    %w[.jpg .json].each do |ext|
      it "#{ext} でのアクセスは 406 を返す（500 にしない）" do
        get "/podcasts/14#{ext}"
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    it 'HTML でのアクセスは従来どおり 200 を返す' do
      get '/podcasts/14'
      expect(response).to have_http_status(:ok)
    end
  end

  it 'HTML でのアクセスは従来どおり 200 を返す' do
    get '/dojos/activity'
    expect(response).to have_http_status(:ok)
  end
end
