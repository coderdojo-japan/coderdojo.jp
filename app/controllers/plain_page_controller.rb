class PlainPageController < CmsController
  #skip_before_action :verify_authenticity_token, only: [:index]

  def index
    @dojos = Dojo.all
  end

  def letsencrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render text: ENV['LETSENCRYPT_RESPONSE']
    else
      render text: 'Failed.'
    end
  end
end
