require 'rails_helper'

RSpec.describe "NewsPages", type: :request do
  describe "GET /news/2016/12/12/new-backend" do
    it "Blog post should be rendered" do
      get '/docs/post-backend-update-history'
      expect(response).to have_http_status(200)
    end
  end
end
