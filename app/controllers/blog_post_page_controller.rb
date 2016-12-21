class BlogPostPageController < CmsController

  def index
    # Use Sitemap
    @sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
  end

end
