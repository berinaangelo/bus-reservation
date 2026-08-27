Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Rider-facing resources go here directly, e.g.:
      #   resources :trips, only: [:index, :show]
      #   resources :bookings, only: [:create, :show]

      # Operator-admin routes live in their own file once there's enough of them to justify it.
      # See kos/decisions/rails-routes-split-into-dedicated-files.md
      draw :operator_admin
    end
  end
end
