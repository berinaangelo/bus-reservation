# CORS for the separate Vue frontend. See kos/decisions/rails-api-only-vue-spa.md.
#
# In local dev this mostly doesn't matter -- Vite's dev server proxies /api/* to Rails
# (frontend/vite.config.ts), so the browser never makes a cross-origin request there. It matters
# for production, where the built Vue assets are served from a different origin than this API.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173")

    resource "/api/*",
      headers: :any,
      methods: %i[get post patch put delete options]
  end
end
