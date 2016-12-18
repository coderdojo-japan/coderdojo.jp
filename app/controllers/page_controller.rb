class PageController < CmsController
  def index
    @dojos = Dojo.all
  end
end
