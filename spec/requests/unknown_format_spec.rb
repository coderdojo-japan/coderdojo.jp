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

  it 'HTML でのアクセスは従来どおり 200 を返す' do
    get '/dojos/activity'
    expect(response).to have_http_status(:ok)
  end
end
