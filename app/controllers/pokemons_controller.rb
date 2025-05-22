class PokemonsController < ApplicationController
  #http_basic_authenticate_with(
  #  name:     ENV['BASIC_AUTH_NAME_FOR_POKEMON'],
  #  password: ENV['BASIC_AUTH_PASSWORD_FOR_POKEMON']) unless Rails.env.development?

  # GET /pokemon
  def new; end

  # GET /pokemon/workshop
  def workshop; end

  # POST /pokemon (Disabled as v2 released)
  def create
    pokemon = Pokemon.create(
      email:            params[:email],
      parent_name:      params[:parent_name],
      participant_name: params[:participant_name],
      dojo_name:        params[:dojo_name],
      presigned_url:    generate_presigned_url,
      download_key:     SecureRandom.urlsafe_base64
    )
    PokemonMailer.with(pokemon: pokemon).send_tos.deliver_now

    redirect_to pokemon_download_path(key: pokemon.download_key)
  end

  # GET /pokemon/download (Disabled as v2 released)
  def show
    pokemon = Pokemon.find_by(download_key: params[:key])
    if pokemon.nil?
      # You can locally debug by 'GET /pokemon/download' in development
      redirect_to pokemon_path, alert: 'ダウンロードのURLが間違っているようです。お手数ですがもう一度お申し込み頂けると幸いです。' unless Rails.env.development?
    elsif pokemon.download_key_expired?
      redirect_to pokemon_path, alert: 'ダウンロードの有効期限が過ぎているようです。お手数ですがもう一度お申し込み頂けると幸いです。'
    end

    # Guard nil because 'redirect_to' above does NOT stop running this code
    @presigned_url = pokemon.presigned_url unless pokemon.nil?
  end

  private

  def generate_presigned_url
    signer = Aws::S3::Presigner.new
    signer.presigned_url(
      :get_object,
      bucket:     'coderdojo-jp-pokemon',
      key:        'pokemon-sozai.zip',
      expires_in: Pokemon::EXPIRATION_MINUTES * 60 # seconds
    )
  end
end
