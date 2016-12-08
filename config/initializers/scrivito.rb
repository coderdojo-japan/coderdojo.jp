Scrivito.configure do |config|
  #
  # Uncomment following lines in order to explicitly set the tenant and the API key.
  # If not explicitly set, the tenant and the API key are obtained from the environment variables
  # SCRIVITO_TENANT and SCRIVITO_API_KEY.
  #
  # config.tenant = 'my-tenant-123'
  # config.api_key = 'secret'
  #

  # Disable the default routes to allow route configuration
  config.inject_preset_routes = false

  #LoginPage Added
  config.editing_auth do |env|
    request = ActionDispatch::Request.new(env)
    if request.session[:user].present?
      Scrivito::User.system_user
    end
  end

end
