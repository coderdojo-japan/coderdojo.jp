require 'rails_helper'

RSpec.describe "Sotechshas", type: :request do

  describe "Quizzes should be permalink" do
    it "Quizzes should be permalink" do
      (0..6).each do |num|
        obj = mock_obj(Obj, permalink: "/sotechsha/#{num}")
        allow(Scrivito::BasicObj).to receive(:find_by_permalink).with("sotechsha/#{num}") { obj }
        get "/sotechsha/#{num}"
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET /sotechsha/gazou" do
    it "Gazoulink should be permalink" do
      obj = mock_obj(Obj, permalink: "/sotechsha/gazou")
      allow(Scrivito::BasicObj).to receive(:find_by_permalink).with("sotechsha/gazou") { obj }
      get "/sotechsha/gazou"
      expect(response).to have_http_status(200)
    end
  end

end
