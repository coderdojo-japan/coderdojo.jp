# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.describe BlogPostPageController, type: :controller do
  render_views

  shared_context 'Get obj' do |path|
    let!(:obj) { Obj.find_by_permalink!(path) }
  end

  describe "GET news" do
    include_context 'Get obj', 'news/2016/12/12/new-backend'

    it "renders its template" do
      request.for_scrivito_obj(obj)
      get :index

      expect(assigns(:sts_posts)).to eq nil
      expect(response).to render_template "blog_post_page/index"
      expect(response).to render_template     partial: "_footer"
      expect(response).to_not render_template partial: "sitemap_sotechsha"
    end
  end

  describe "GET sotechsha" do
    include_context 'Get obj', 'sotechsha/0'

    it "renders its template" do
      request.for_scrivito_obj(obj)
      get :index

      sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
      expect(assigns(:sts_posts).to_a).to eq sts_posts.to_a

      expect(response).to render_template "blog_post_page/index"
      expect(response).to render_template partial: "_sitemap_sotechsha"
      expect(response).to render_template partial: "_footer"
    end
  end
end
