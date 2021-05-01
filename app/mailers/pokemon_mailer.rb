class PokemonMailer < ApplicationMailer
  def send_tos
    @pokemon = params[:pokemon]
    mail(to: @pokemon.email, subject: 'ポケモン素材の利用申し込みありがとうございます')
  end
end
