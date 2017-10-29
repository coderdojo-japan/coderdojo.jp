require 'rails_helper'

RSpec.describe BlogPostPageController, type: :controller do
  render_views

  xdescribe "GET Blog Post Page" do
    it "normal blog post" do
      obj = Obj.find_by_permalink!("news/2016/12/12/new-backend")
      request.for_scrivito_obj(obj)
      get :index
      expect(assigns(:sts_posts)).to eq nil
      expect(response).to render_template "blog_post_page/index", count:1
      expect(response).to_not render_template partial: "sitemap_sotechsha"
      expect(response).to render_template partial: "_footer", count:1
    end

    it "sotechsha post" do
      obj = Obj.find_by_permalink!("sotechsha/0")
      request.for_scrivito_obj(obj)
      get :index
      sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
      expect(assigns(:sts_posts).to_a).to eq sts_posts.to_a
      expect(response).to render_template "blog_post_page/index"
      expect(response).to render_template partial: "_sitemap_sotechsha", count: 1
      expect(response).to render_template partial: "_footer", count: 1
     end
  end
end
