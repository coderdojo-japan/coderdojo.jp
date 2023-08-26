class StaticPagesController < ApplicationController
  def lets_encrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render plain: ENV['LETSENCRYPT_RESPONSE']
    else
      render plain: 'Failed.'
    end
  end

  def security
    render plain: File.read(Rails.public_path.join 'security.txt')
  end
end
