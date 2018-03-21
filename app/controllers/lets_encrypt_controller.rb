class LetsEncryptController < ApplicationController
  def show
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render plain: ENV['LETSENCRYPT_RESPONSE']
    else
      render plain: 'Failed.'
    end
  end
end
