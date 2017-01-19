require 'rails_helper'

RSpec.describe "Sotechshas", type: :request do
  
  describe "Quizzes should be permalink" do
    it "Quizzes should be permalink" do
      (0..6).each do |num|
        get "/sotechsha/#{num}"
        expect(response).to have_http_status(200)
        expect(response).to render_template(:partial => "_sitemap_sotechsha" ,:count=> 1)
        expect(response).to render_template(:partial => "_footer",:count => 1)
      end
    end
  end

  describe "GET /sotechsha/gazou" do
    it "Gazoulink should be permalink" do
      get "/sotechsha/gazou"
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /sotechsha" do
    it "SoTechSha link should be rendered" do
      get "/sotechsha"
      expect(response).to render_template "sotechsha_overview_page/index"
      expect(response).to render_template partial: "_sitemap_sotechsha" ,count: 1
      expect(response).to render_template partial: "_footer", count: 1
      expect(response).to render_template partial: "_social_buttons", count: 1
    end
  end

end
