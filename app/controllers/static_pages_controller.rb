class StaticPagesController < ApplicationController
  def home
    @dojos = Dojo.all
    @regions_and_dojos = Prefecture.regions.map do |region|
      [region, Dojo.find_by_region(region)]
    end.to_h
  end

  def letsencrypt
    if params[:id] == ENV['LETSENCRYPT_REQUEST']
      render text: ENV['LETSENCRYPT_RESPONSE']
    else
      render text: 'Failed.'
    end
  end
end
