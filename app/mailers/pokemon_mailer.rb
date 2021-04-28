class PokemonMailer < ApplicationMailer
  def send_tos
    @pokemon = params[:pokemon]
    mail(to: @pokemon.email, subject: 'ポケモン素材のダウンロードについて')
  end
end
