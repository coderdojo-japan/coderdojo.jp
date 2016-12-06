require 'test_helper'

class SoTechShaTest < ActionDispatch::IntegrationTest
  def setup
    # Quizzes on the book
    @quizzes = (1..6).to_a
  end

  test "Quizzes should be redirected" do
    @quizzes.each do |num|
      get "/sotechsha/#{num}"
      assert_redirected_to "/sotechsha-#{num}"
    end
  end

  test "Gazoulink should be redirected" do
    get "/sotechsha/gazou"
    assert_redirected_to "/sotechsha-gazou"
  end

  test "SoTechShalink should be rendered" do
    get "/sotechsha"
    #so_tech_sha_overview_page.index がrenderされる
    #タイトルが「「Scratchでつくる! たのしむ! プログラミング道場」Webコンテンツ」である
    #記事の件数　7件である
  end
end
