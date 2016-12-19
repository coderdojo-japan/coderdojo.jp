class SoTechShaOverviewPageController < CmsController
  POSTS_PER_PAGE = 10

  def index
    offset = params[:offset].to_i

    sts_posts_query = BlogPostPage.where(:_permalink, :starts_with, 'sotechsha/').order(created: :asc)
    sts_posts_query.batch_size(POSTS_PER_PAGE).offset(offset)
    @sts_posts = sts_posts_query.take(POSTS_PER_PAGE)

    total = sts_posts_query.size

    if offset > 0
      @previous_page = scrivito_path(@obj, offset: offset - POSTS_PER_PAGE)
    end

    if total > offset + POSTS_PER_PAGE
      @next_page = scrivito_path(@obj, offset: offset + POSTS_PER_PAGE)
    end
  end

end
