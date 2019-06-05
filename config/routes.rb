Rails.application.routes.draw do
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  root "home#show"

  # Render legal documents by using Keiyaku CSS
  # https://github.com/cognitom/keiyaku-css
  get "/docs/code_of_conduct",  to: redirect('/docs/code-of-conduct')
  get "/docs/charter",          to: redirect('/charter')
  get "/docs/charter_en",       to: redirect('/charter_en')
  get "/docs/financial-report", to: redirect('/financial-report')
  get "/login",                 to: redirect('/login-8717e64efaf19d7d')
  get "/youtube",               to: redirect('https://www.youtube.com/channel/UCal5GuoCDCMDQe07w69TuJA')
  get "/podcasts/feed"    => "podcasts#feed"
  get "/charter"          => "docs#show", id: 'charter'
  get "/charter_en"       => "docs#show", id: 'charter_en'
  get "/financial-report" => "docs#show", id: 'financial-report'
  resources :docs,     only: %i(index show)
  resources :podcasts, only: %i(index show)
  resources :spaces,   only: %i(index)

  get "/stats"      => "stats#show"
  # TODO: Need to investigate why the following code calls Scrivito.
  #       Hotfix with the code above that works correctly.
  #resources :stats,  only: %i(show)

  # Upcoming Events
  get "/events"  => "events#index"

  # Redirects
  get "/releases/2016/12/12/new-backend", to: redirect('/news/2016/12/12/new-backend')
  get "/blogs/2016/12/12/new-backend",    to: redirect('/news/2016/12/12/new-backend')

  # Issue SSL Certification
  get "/.well-known/acme-challenge/:id" => "lets_encrypt#show"

  # Sessions
  get '/logout',       to: 'sessions#destroy'
  resource :session, only: [:create, :destroy]

  # Default Scrivito routes. Adapt them to change the routing of CMS objects.
  # See the documentation of 'scrivito_route' for a detailed description.
  scrivito_route '/',              using: 'homepage'
  scrivito_route '(/)(*slug-):id', using: 'slug_id'
  scrivito_route '/*permalink',    using: 'permalink', format: false
end
