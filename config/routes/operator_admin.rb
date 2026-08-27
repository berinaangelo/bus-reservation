# Operator-admin routes (Route/Trip/BusUnit/FareRule CRUD, Trip Manifest check-in), scoped to
# OperatorStaff's own operator. Loaded via `draw :operator_admin` from config/routes.rb.
# See kos/decisions/rails-routes-split-into-dedicated-files.md
namespace :operator do
  # resources :routes
  # resources :trips
  # resources :bus_units
  # resources :fare_rules
end
