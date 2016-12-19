# -*- coding: utf-8 -*-
require 'test_helper'

class BlogTest < ActionDispatch::IntegrationTest
  def setup
  end

  test "Blog post should be rendered" do
    get "/blogs/2016/12/12/new-backend"
    assert_template "blog_post_page/index"
    assert_select "title", "CoderDojo Japan のバックエンドを更新しました - CoderDojo Japan"
  end
end
