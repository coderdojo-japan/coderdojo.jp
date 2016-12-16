# -*- coding: utf-8 -*-
class BlogOverviewPageController < CmsController
  POSTS_PER_PAGE = 10

  def index
    offset = params[:offset].to_i

    blog_posts_query = BlogPostPage.all.order(created: :desc)
    blog_posts_query.batch_size(POSTS_PER_PAGE).offset(offset)
    @blog_posts = blog_posts_query.take(POSTS_PER_PAGE)

    total = blog_posts_query.size

    if offset > 0
      @previous_page = scrivito_path(@obj, offset: offset - POSTS_PER_PAGE)
    end

    if total > offset + POSTS_PER_PAGE
      @next_page = scrivito_path(@obj, offset: offset + POSTS_PER_PAGE)
    end
  end

end
