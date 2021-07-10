Rails.application.routes.draw do
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  root "home#show"

  # Debug URL
  get "/debug" => "home#debug"

  # Render legal documents by using Keiyaku CSS
  # https://github.com/cognitom/keiyaku-css
  #get "/docs/code_of_conduct",   to: redirect('/docs/code-of-conduct')
  #get "/docs/charter",           to: redirect('/charter')
  #get "/docs/charter_en",        to: redirect('/charter_en')
  #get "/docs/styleguides",       to: redirect('/styleguides')
  #get "/docs/about-partnership", to: redirect('/partnership')
  #get "/docs/financial-report",  to: redirect('/financial-report')
  #get "/docs/privacy",           to: redirect('/privacy')
  #get "/docs/teikan",            to: redirect('/teikan')
  #get "/docs/signup",            to: redirect('/signup')
  #get "/docs/join-in-board",     to: redirect('/join-in-board')
  get "/docs/join-in-board-2017", to: redirect('/join-in-board-2017')
  get "/docs/thanks",             to: redirect('/thanks')
  get "/docs/calendar-yohei",     to: redirect('/calendar/yohei')
  get "/docs/calendar-kirie",     to: redirect('/calendar/kirie')

  get "/login",                   to: redirect('/login-8717e64efaf19d7d')
  get "/youtube",                 to: redirect('https://www.youtube.com/CoderDojoJapan')
  get "/brand",                   to: redirect('/docs/brand-guidelines')
  get "/calendar",                to: redirect('/calendar/yohei')
  get "/calendar-yohei",          to: redirect('/calendar/yohei')
  get "/calendar-kirie",          to: redirect('/calendar/kirie')
  get "/calendar/yohei"   => "docs#show", id: 'calendar-yohei'
  get "/calendar/kirie"   => "docs#show", id: 'calendar-kirie'
  get "/charter"          => "docs#show", id: 'charter'
  get "/charter_en"       => "docs#show", id: 'charter_en'
  get "/styleguides"      => "docs#show", id: 'styleguides'
  get "/partner",         to: redirect('/partnership')
  get "/partnership"      => "docs#show", id: 'about-partnership'
  get "/financial-report" => "docs#show", id: 'financial-report'
  get "/privacy"          => "docs#show", id: 'privacy'
  get "/teikan"           => "docs#show", id: 'teikan'
  get "/join-in-board"      => "docs#show", id: 'join-in-board'
  get "/join-in-board-2017" => "docs#show", id: 'join-in-board-2017'
  get "/thanks"           => "docs#show", id: 'thanks'
  get "/signup"           => "docs#show", id: 'signup'

  resources :docs,     only: %i(index show)
  resources :podcasts, only: %i(index show)
  resources :spaces,   only: %i(index)

  get  "/podcast",         to: redirect('/podcasts')
  get  "/podcasts/feed"    => "podcasts#feed"
  get  "/stats"            => "stats#show"
  get  "/pokemon"          => "pokemons#new"
  post "/pokemon"          => "pokemons#create"
  get  "/pokemon/download" => "pokemons#show"
  # TODO: Need to investigate why the following code calls Scrivito.
  #       Hotfix with the code above that works correctly.
  #resources :stats,  only: %i(show)
  #resources :pokemons,  only: %i(index create)

  # Upcoming Events
  get "/events"  => "events#index"

  # Redirects
  get "/releases/2016/12/12/new-backend", to: redirect('/docs/post-backend-update-history')
  get "/blogs/2016/12/12/new-backend",    to: redirect('/docs/post-backend-update-history')
  get "/news/2016/12/12/new-backend",     to: redirect('/docs/post-backend-update-history')

  # Issue SSL Certification
  get "/.well-known/acme-challenge/:id" => "lets_encrypt#show"

  # Sessions
  get '/logout',       to: 'sessions#destroy'
  resource :session, only: [:create, :destroy]

  # Check development sent emails
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Default Scrivito routes. Adapt them to change the routing of CMS objects.
  # See the documentation of 'scrivito_route' for a detailed description.
  scrivito_route '/',              using: 'homepage'
  scrivito_route '(/)(*slug-):id', using: 'slug_id'
  scrivito_route '/*permalink',    using: 'permalink', format: false
end
