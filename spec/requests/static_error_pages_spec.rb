require 'rails_helper'

# エラーページは n (旧 rambulance) gem で app/views/errors/ に実装している。
# しかし Rails 標準の静的ファイル public/404.html などが残っていると、
# /404 のような URL で静的ファイルが先にヒットし、HTTP 200 で Rails 標準の
# 英語のページが表示されてしまう（カスタムページは表示されない）。
RSpec.describe 'Static error pages', type: :request do
  %w[400 404 422 500].each do |code|
    it "GET /#{code} が Rails 標準の静的ページを返さない" do
      get "/#{code}"

      expect(response.status).not_to eq(200),
        "Rails 標準の public/#{code}.html が残っていると、HTTP 200 で英語の標準ページが表示されます"
      expect(response.body).not_to include('The page you were looking for')
    end
  end
end
