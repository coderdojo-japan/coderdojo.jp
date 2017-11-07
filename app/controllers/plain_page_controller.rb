class PlainPageController < CmsController
  #skip_before_action :verify_authenticity_token, only: [:index]

  def index
    @dojos = Dojo.all
  end
end
