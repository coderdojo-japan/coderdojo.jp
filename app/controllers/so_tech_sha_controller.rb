class SoTechShaController < ApplicationController
  def quiz
    quiz = params[:quiz]
    redirect_to "/sotechsha-#{quiz}"
  end
end
