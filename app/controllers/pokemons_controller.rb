class PokemonsController < ApplicationController
  if Rails.env.staging? || Rails.env.production?
    http_basic_authenticate_with name: ENV['BASIC_AUTH_NAME_FOR_POKEMON'],
                                 password: ENV['BASIC_AUTH_PASSWORD_FOR_POKEMON']
  end
  before_action :download_key_present?, only: :download

  def new; end

  def create
    pokemon = Pokemon.create(
      email: params[:email],
      parent_name: params[:parent_name],
      participant_name: params[:participant_name],
      dojo_name: params[:dojo_name],
      presigned_url: generate_presigned_url,
      download_key: SecureRandom.hex
    )
    redirect_to pokemon_download_path(key: pokemon.download_key)
  end

  def show
    pokemon_download_key = Pokemon.find_by(download_key: params[:key])
    @presigned_url = pokemon_download_key.presigned_url
  end

  private

  def generate_presigned_url
    signer = Aws::S3::Presigner.new
    signer.presigned_url(
      :get_object,
      bucket: 'coderdojo-jp-pokemon',
      key: 'pokemon-sozai.zip',
      expires_in: 3600
    )
  end

  def download_key_present?
    redirect_to pokemon_path, alert: 'ダウンロードキーがありません。もう一度申し込んでください。' if params[:key].blank?
  end
end
