require 'rails_helper'

RSpec.describe "NewsPages", type: :request do
  describe "GET /news/2016/12/12/new-backend" do
    it "Blog post should be rendered" do
      get '/news/2016/12/12/new-backend'
      expect(response).to have_http_status(200)
      expect(response).to render_template "blog_post_page/index"
      expect(response).not_to render_template partial: "_sitemap_sotechsha"
      expect(response).to render_template partial: "_footer", count: 1
    end
  end
end
