# Action Cable's own origin check (distinct from Rack::Cors in config/initializers/cors.rb, which
# only guards /api/*) -- without this, the browser's WebSocket handshake to /cable from the
# separate Vue origin is rejected. Same FRONTEND_ORIGIN env var as cors.rb; the two must point at
# the same place. See kos/decisions/rails-api-only-vue-spa.md.
Rails.application.config.action_cable.allowed_request_origins = [
  ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173")
]
