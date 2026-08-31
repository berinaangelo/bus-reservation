# Operator-admin routes (Route/Trip/BusUnit/FareRule CRUD, Trip Manifest check-in), scoped to
# OperatorStaff's own operator. Loaded via `draw :operator_admin` from config/routes.rb.
# See kos/decisions/rails-routes-split-into-dedicated-files.md
namespace :operator do
  resource :session, only: [ :create, :destroy, :update ]
  resources :password_resets, only: [ :create, :update ], param: :token
  resources :staff, only: [ :index, :create, :update ]

  resources :trips, only: [ :index, :show, :create, :update, :destroy ] do
    resource :manifest, only: [ :show ], controller: "trip_manifests"
    resources :check_ins, only: [ :create ]
  end

  resources :payments, only: [ :update ]

  resources :routes
  resources :bus_units
  resources :fare_rules
end
