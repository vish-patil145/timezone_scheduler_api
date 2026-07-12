require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  namespace :api do
    namespace :v1 do
      resources :users, only: [ :create ]
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
