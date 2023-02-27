require 'rails_helper'

RSpec.describe "Sotechsha2s", type: :request do
  describe "Quizzes should be permalink" do
    it "Quizzes should be permalink" do
      (0..6).each do |num|
        get "/sotechsha2/#{num}"
        expect(response).to have_http_status(200)
      end
    end
  end
end
