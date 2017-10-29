class StaticPagesController < ApplicationController
  def home
    @dojos = Dojo.all
  end
end
