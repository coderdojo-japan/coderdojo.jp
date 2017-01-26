require 'rails_helper'

RSpec.describe SotechshaOverviewPageController, type: :controller do
  render_views

  describe "GET #index" do
    it "set @sts_post" do
      obj = Obj.find_by_permalink!("sotechsha")
      request.for_scrivito_obj(obj)
      get :index
      sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
      expect(controller.instance_variable_get("@sts_posts")).to eq sts_posts
      expect(response).to render_template "sotechsha_overview_page/index"
      expect(response).to render_template partial: "_sitemap_sotechsha", count: 1
      expect(response).to render_template partial: "_footer", count: 1
      expect(response).to render_template partial: "_social_buttons", count: 1
    end
  end
end
