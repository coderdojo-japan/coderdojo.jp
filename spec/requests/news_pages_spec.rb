require 'rails_helper'

RSpec.describe "NewsPages", type: :request do
  describe "GET /news/2016/12/12/new-backend" do
    it "Blog post should be rendered" do
      obj = mock_obj(Obj, permalink: "/news/2016/12/12/new-backend")
      allow(Scrivito::BasicObj).to receive(:find_by_permalink).with("news/2016/12/12/new-backend") { obj }
      get '/news/2016/12/12/new-backend'
      expect(response).to have_http_status(200)
    end
  end
end
