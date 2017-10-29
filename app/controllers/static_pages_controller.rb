class StaticPagesController < ApplicationController
  def home
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
