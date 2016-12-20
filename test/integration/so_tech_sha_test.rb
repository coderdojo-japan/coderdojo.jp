# -*- coding: utf-8 -*-
require 'test_helper'

class SoTechShaTest < ActionDispatch::IntegrationTest
  def setup
    # Quizzes on the book
    @quizzes = (0..6).to_a
  end

  test "Quizzes should be permalink" do
    @quizzes.each do |num|
      get "/sotechsha/#{num}"
      assert_response :success
      assert_equal "/sotechsha/#{num}", path
      # num = num == 0 ? "序" : num
      # assert_select 'h1', "#{num}章課題　模範解答"
    end
  end

  test "Gazoulink should be permalink" do
    get "/sotechsha/gazou"
    assert_response :success
  end

  test "SoTechShalink should be rendered" do
    get "/sotechsha"
    assert_template "so_tech_sha_overview_page/index"
    assert_select "h1.page-header","「Scratchでつくる! たのしむ! プログラミング道場」Webコンテンツ"
    assert_select "a[href]", count:16
    # Error
    # assert_select "a[href=?]", /sotechsha-/ , count:14
    assert_select "img", count:1
  end

  test "Datetime should be formatted" do
    post_path = "sotechsha/1"
    get "/#{post_path}"
    assert_select ".h4", /^\d{4}年\d{2}月\d{2}日$/
  end
end
