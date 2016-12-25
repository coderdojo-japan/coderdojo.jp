# -*- coding: utf-8 -*-
require 'test_helper'

class BlogTest < ActionDispatch::IntegrationTest
  def setup
  end

  test "Blog post should be rendered" do
    get "/news/2016/12/12/new-backend"
    assert_template "blog_post_page/index"
    assert_template partial: '_sitemap_sotechsha', count: 0
    assert_template partial: '_footer', count: 1
    assert_select "title", "CoderDojo Japan のバックエンドを更新しました - CoderDojo Japan"
  end
end
