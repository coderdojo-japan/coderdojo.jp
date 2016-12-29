# -*- coding: utf-8 -*-
require 'test_helper'

require 'minitest/retry'
Minitest::Retry.use!(
  retry_count:  3,         # The number of times to retry. The default is 3.
  verbose: true,           # Whether to display the message at the time of retry. The default is true.
  io: $stdout,             # Display destination of retry when the message. The default is stdout.
  exceptions_to_retry: []  # List of exceptions that will trigger a retry (when empty, all exceptions will).
)

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
