Rails.application.routes.draw do
  # Redirects
  get "/releases/2016/12/12/new-backend", to: redirect('/news/2016/12/12/new-backend')
  get "/blogs/2016/12/12/new-backend",    to: redirect('/news/2016/12/12/new-backend')

  # Issue SSL Certification
  get "/.well-known/acme-challenge/:id" => "page#letsencrypt"

  # Sessions
  get '/logout',       to: 'sessions#destroy'
  resource :session, only: [:create, :destroy]

  # Default Scrivito routes. Adapt them to change the routing of CMS objects.
  # See the documentation of 'scrivito_route' for a detailed description.
  scrivito_route '/',              using: 'homepage'
  scrivito_route '(/)(*slug-):id', using: 'slug_id'
  scrivito_route '/*permalink',    using: 'permalink', format: false
end
