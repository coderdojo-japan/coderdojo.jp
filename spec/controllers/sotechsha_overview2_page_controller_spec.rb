require 'rails_helper'

RSpec.describe SotechshaOverview2PageController, type: :controller, scrivito: true do
  render_views

  xdescribe "GET #index" do
    it "set @sts_post" do
      obj = Obj.find_by_permalink!("sotechsha2")
      request.for_scrivito_obj(obj)
      get :index
      sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha2/').order(created: :asc)
      expect(assigns(:sts_posts).to_a).to eq sts_posts.to_a
      expect(response).to render_template "sotechsha_overview2_page/index"
      expect(response).to render_template partial: "_sitemap_sotechsha",  count: 1
      expect(response).to render_template partial: "_footer",             count: 1
      expect(response).to render_template partial: "_social_buttons_raw", count: 1
    end
  end
end
