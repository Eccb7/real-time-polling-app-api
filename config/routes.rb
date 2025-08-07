Rails.application.routes.draw do
  # Action Cable mount point
  mount ActionCable.server => "/cable"

  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      # Polls routes
      resources :polls do
        member do
          get :results
        end
        collection do
          get :my_polls
        end

        # Nested votes routes
        resources :votes, only: [ :create, :destroy ]
      end

      # Standalone votes routes for convenience
      resources :votes, only: [ :destroy ]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route
  root "rails/health#show"
end
