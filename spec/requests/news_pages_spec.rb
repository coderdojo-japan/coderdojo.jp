require 'rails_helper'

RSpec.describe "NewsPages", type: :request, scrivito: true do
  describe "GET /news/2016/12/12/new-backend" do
    it "Blog post should be rendered" do
      get '/news/2016/12/12/new-backend'
      expect(response).to have_http_status(200)
    end
  end
end
