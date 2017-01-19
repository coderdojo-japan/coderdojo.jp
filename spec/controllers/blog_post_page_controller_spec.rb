require 'rails_helper'

RSpec.describe BlogPostPageController, type: :controller do

    describe "GET Blog Post Page" do
        it "render blog post" do
            get "/news/2016/12/12/new-backend"
            expect(response).to render_template("blog_post_page/index")
            expect(view).not_to render_template(:partial => "_sitemap_sotechsha")
            expect(view).to render_template(:partial => "_footer",:count => 1)
        end
    end

end
