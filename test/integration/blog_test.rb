require 'test_helper'

class BlogTest < ActionDispatch::IntegrationTest
  def setup
  end

  test "Bloglink should be rendered" do
    get "/blog"
    assert_template "blog_overview_page/index"
    assert_select "h1.page-header","Page Overview"
  end
end
