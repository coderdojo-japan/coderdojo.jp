class SotechshaOverview2PageController < CmsController
  def index

    @sts_posts = BlogPostPage.where(:_permalink, :starts_with,
                                    'sotechsha2/').order(created: :asc)
  end
end
