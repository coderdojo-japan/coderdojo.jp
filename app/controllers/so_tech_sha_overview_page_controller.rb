class SoTechShaOverviewPageController < CmsController

  def index
    @sts_posts = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
  end

end
