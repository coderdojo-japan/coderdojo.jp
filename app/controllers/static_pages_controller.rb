class StaticPagesController < ApplicationController
  def home
    @dojo_count = Dojo.count
    @regions_and_dojos = Dojo.includes(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
  end

  def letsencrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render text: ENV['LETSENCRYPT_RESPONSE']
    else
      render text: 'Failed.'
    end
  end
end
