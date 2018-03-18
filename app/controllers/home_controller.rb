class HomeController < ApplicationController
  def show
    @dojo_count        = Dojo.count
    @regions_and_dojos = Dojo.eager_load(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
  end
end
