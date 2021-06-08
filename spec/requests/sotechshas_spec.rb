require 'rails_helper'

RSpec.describe "Sotechshas", type: :request, scrivito: true do

  xdescribe "Quizzes should be permalink" do
    it "Quizzes should be permalink" do
      (0..6).each do |num|
        get "/sotechsha/#{num}"
        expect(response).to have_http_status(200)
      end
    end
  end

  xdescribe "GET /sotechsha/gazou" do
    it "Gazoulink should be permalink" do
      get "/sotechsha/gazou"
      expect(response).to have_http_status(200)
    end
  end

end
