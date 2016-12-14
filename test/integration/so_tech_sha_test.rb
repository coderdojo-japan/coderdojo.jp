# -*- coding: utf-8 -*-
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
    assert_template "so_tech_sha_overview_page/index"
    assert_select "h1.page-header","「Scratchでつくる! たのしむ! プログラミング道場」Webコンテンツ"
    assert_select "a[href]", count:14
    # Error
    # assert_select "a[href=?]", /sotechsha-/ , count:14
    assert_select "img", count:1
  end

  test "Datetime should be formatted" do
    post_path = "sotechsha-1"
    get "/#{post_path}"
    assert_select ".h4", /^\d{4}\/\d{2}\/\d{2}$/
  end
end
