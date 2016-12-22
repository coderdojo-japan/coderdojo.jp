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
      # TODO: Test 1 and 3  they are ready
      next if num == 1 or num == 3
      ch = num.to_s.tr("0-9", "０-９").gsub("０", "序")
      assert_select 'h1', "#{ch}章課題"
    end
  end

  test "Gazoulink should be permalink" do
    get "/sotechsha/gazou"
    assert_response :success
  end

  test "SoTechSha link should be rendered" do
    get "/sotechsha"
    assert_template "so_tech_sha_overview_page/index"
    #assert_select "h1.page-header", "Scratchでつくる! たのしむ! プログラミング道場"
    assert_select "a[href]", count:24
    assert_select "footer", count:1
    # topimg,snsbtn
    assert_select "img", count:2
  end

  test "Datetime should be formatted" do
    post_path = "sotechsha/1"
    get "/#{post_path}"
    assert_select ".h4", /^\d{4}年\d{2}月\d{2}日$/
  end
end
