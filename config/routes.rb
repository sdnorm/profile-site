Rails.application.routes.draw do
  personal_host = /(\A|\.)spencernorman\.(io|localhost)\z/
  studio_host   = /(\A|\.)normansimplified\.(com|localhost)\z/

  # ---- Non-canonical production hosts -> the one host search engines should index ----
  { "normansimplified.com" => "www.normansimplified.com", "www.spencernorman.io" => "spencernorman.io" }.each do |from, to|
    constraints(host: from) do
      get "(*path)", to: redirect(host: to, protocol: "https"), format: false
    end
  end

  # ---- Norman Simplified (www.normansimplified.com) ----
  constraints(host: studio_host) do
    scope module: :studio, as: :studio do
      root "pages#home"
      get  "ai-integration", to: "pages#ai_integration", as: :ai_integration
      get  "how-we-work",    to: "pages#how_we_work",    as: :how_we_work
      get  "contact",        to: "inquiries#new",        as: :contact
      post "contact",        to: "inquiries#create"
      get  "sitemap.xml",    to: "sitemaps#show", defaults: { format: :xml }
      get  "robots.txt",     to: "robots#show",   defaults: { format: :text }
    end
  end

  # ---- Personal portfolio (spencernorman.io) ----
  constraints(host: personal_host) do
    scope module: :personal, as: :personal do
      root "pages#home"
      post "contact", to: "contacts#create", as: :contact
      get  "sitemap.xml", to: "sitemaps#show", defaults: { format: :xml }
      get  "robots.txt",  to: "robots#show",   defaults: { format: :text }
    end
  end

  # ---- Legacy demo / auth features (relocation tracked in card #117) ----
  resource :registration
  resource :session
  resource :qr_session
  get "qr_sessions", to: "qr_sessions#qr_sign_in", as: :qr_sign_in
  get "date_parser/index"
  post "date_parse" => "date_parser#parse", as: :date_parse

  # Reveal health status on /up that returns 200 if the app boots with no exceptions.
  get "up" => "rails/health#show", as: :rails_health_check

  # Default root for any non-site host (bare localhost, IP) -> personal home.
  # Keeps `root_path` defined for the legacy controllers that still use it.
  root "personal/pages#home"
end
