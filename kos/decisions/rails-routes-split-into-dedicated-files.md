---
title: rails-routes-split-into-dedicated-files
tags: [bus-reservation, rails, backend, routing]
date: 2026-08-25
---

Keep `config/routes.rb` short. Once a section grows large (e.g. operator-admin routes vs.
rider-facing routes), split it into its own file rather than piling more lines into the main
file.

Rails supports drawing routes from separate files via `draw(:name)`, which loads
`config/routes/name.rb`:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :trips, only: [:index, :show]
      resources :bookings, only: [:create, :show]

      draw :operator_admin   # loads config/routes/operator_admin.rb
    end
  end
end
```

```ruby
# config/routes/operator_admin.rb
namespace :operator do
  resources :routes
  resources :trips
  resources :fare_rules
end
```

Default to one file per major area (rider-facing API vs. operator-admin API) once it stops being
a handful of lines, rather than one giant `routes.rb`.
