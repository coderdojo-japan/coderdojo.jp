class BlogPostPageController < CmsController

  def index
    if @obj.permalink.to_s.include?("sotechsha/")
      # Use Sitemap
      @sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
    elsif @obj.permalink.to_s.include?("sotechsha2/")
      @sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha2/').order(created: :asc)
    end
  end

end
