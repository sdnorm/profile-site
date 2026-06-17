Rails.application.routes.draw do
  get "general/index"
  get "date_parser/index"
  post "date_parse" => "date_parser#parse", as: :date_parse

  resource :registration
  resource :session
  resource :qr_session
  get "qr_sessions", to: "qr_sessions#qr_sign_in", as: :qr_sign_in

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "general#index"
end
