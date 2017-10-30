class BlogPostPageController < ScrivitoController

  def index
    if @obj.permalink.to_s.include?("sotechsha/")
      # Use Sitemap
      @sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
    end
  end

end
