Rails.application.routes.draw do
  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html

  root "home#show"

  # Render legal documents by using Keiyaku CSS
  # https://github.com/cognitom/keiyaku-css
  #get "/docs/code_of_conduct",   to: redirect('/docs/code-of-conduct')
  #get "/docs/charter",           to: redirect('/charter')
  #get "/docs/charter_en",        to: redirect('/charter_en')
  #get "/docs/styleguides",       to: redirect('/styleguides')
  #get "/docs/about-partnership", to: redirect('/partnership')
  #get "/docs/privacy",           to: redirect('/privacy')
  #get "/docs/teikan",            to: redirect('/teikan')
  #get "/docs/signup",            to: redirect('/signup')

  get "/docs/join-in-board",      to: redirect('/about-coderdojo-japan')
  get "/docs/join-in-board-2017", to: redirect('/about-coderdojo-japan')
  get "/join-in-board",           to: redirect('/about-coderdojo-japan')
  get "/join-in-board-2017",      to: redirect('/about-coderdojo-japan')
  get "/about-coderdojo-japan"    => "docs#show", id: 'about-coderdojo-japan'
  get "/about-coderdojo"          => "docs#show", id: 'about-coderdojo'

  get "/docs/brand-guidelines",   to: redirect('/brand')
  get "/docs/thanks",             to: redirect('/thanks')
  get "/docs/financial-report",   to: redirect('/finances')
  get "/docs/finances",           to: redirect('/finances')
  get "/docs/for-media",          to: redirect('/for-media')

  get "/docs/_calendar-yohei",    to: redirect('/calendar/yohei')
  get "/docs/_calendar-kirie",    to: redirect('/calendar/kirie')
  get "/docs/_thanks",            to: redirect('/thanks')

  get "/redirects/202407",        to: redirect('https://www.facebook.com/groups/coderdojo.jp.champions/posts/7788378511253707/')
  get "/redirects/interface",     to: redirect('/')
  get "/youtube",                 to: redirect('https://www.youtube.com/CoderDojoJapan')
  get "/calendar",                to: redirect('/calendars')
  get "/calendars",               to: redirect('/calendars/yohei')
  get "/calendar/yohei",          to: redirect('/calendars/yohei')
  get "/calendar/kirie",          to: redirect('/calendars/kirie')
  get "/calendars/yohei"  => "docs#show", id: '_calendar-yohei'
  get "/calendars/kirie"  => "docs#show", id: '_calendar-kirie'
  get "/thanks"           => "docs#show", id: '_thanks'

  get "/brand"            => "docs#show", id: 'brand-guidelines'
  get "/charter"          => "docs#show", id: 'charter'
  get "/charter_en"       => "docs#show", id: 'charter_en'
  get "/english"          => "docs#show", id: 'english'
  get "/for-media"        => "docs#show", id: 'for-media'
  get "/styleguides"      => "docs#show", id: 'styleguides'

  get "/financial-report",      to: redirect('/finances')
  get "/finances"         => "docs#show", id: 'finances'

  get "/partner",         to: redirect('/partnership')
  get "/partnership"      => "docs#show", id: 'about-partnership'
  get "/privacy"          => "docs#show", id: 'privacy'
  get "/teikan"           => "docs#show", id: 'teikan'
  get "/signup"           => "docs#show", id: 'signup'
  get "/kata"             => "docs#kata"
  #get "/debug/kata"       => "docs#kata"

  resources :dojos,    only: %i(index) # GET /dojos.json returns dojo data as JSON
  resources :docs,     only: %i(index show)
  resources :podcasts, only: %i(index show)
  resources :spaces,   only: %i(index)

  get "/podcast",         to: redirect('/podcasts')
  get "/podcasts/feed"    => "podcasts#feed"
  get "/stats"            => "stats#show"
  get "/pokemon"          => "pokemons#new"
  #post "/pokemon"          => "pokemons#create"
  #get  "/pokemon/download" => "pokemons#show"
  get "/pokemon/download", to: redirect('/pokemon')
  get "/pokemon/workshop"  => "pokemons#workshop"

  # TODO: Need to investigate why the following code calls Scrivito.
  #       Hotfix with the code above that works correctly.
  #resources :stats,  only: %i(show)
  #resources :pokemons,  only: %i(index create)

  # Upcoming Events & Latest Events
  get '/events'        => 'events#index'
  get '/events/latest' => 'events#latest'

  # Redirects
  get "/releases/2016/12/12/new-backend", to: redirect('/docs/post-backend-update-history')
  get "/blogs/2016/12/12/new-backend",    to: redirect('/docs/post-backend-update-history')
  get "/news/2016/12/12/new-backend",     to: redirect('/docs/post-backend-update-history')

  # Issue SSL Certification
  get "/.well-known/acme-challenge/:id" => "static_pages#lets_encrypt"
  get "/.well-known/security.txt"       => "static_pages#security"

  # CoderDojo Books from Sotechsha
  get "/sotechsha"       => "sotechsha_pages#index"
  get "/sotechsha/:page" => "sotechsha_pages#show"

  get "/sotechsha2"       => "sotechsha2_pages#index"
  get "/sotechsha2/:page" => "sotechsha2_pages#show"

  # Check development sent emails
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
