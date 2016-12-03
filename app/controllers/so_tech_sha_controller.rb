class SoTechShaController < ApplicationController
  def quiz
    quiz = params[:quiz]
    redirect_to "/#{quiz}"
  end
end
