---
title: rails-activejob-solid-queue-for-background-work
tags: [bus-reservation, rails, backend, infrastructure]
date: 2026-08-25
---

Anything that doesn't need to happen synchronously in the request/Interactor goes through
ActiveJob, not inline.

**Direct fit: the seat-hold expiry sweep** — an MVP-critical piece per [[mvp-scope]] and
[[seat-hold-ttl]]. Without it, abandoned checkouts leave TripSeats stuck `held` forever.

```ruby
class ReleaseExpiredSeatHoldsJob < ApplicationJob
  def perform
    TripSeat.where(status: :held).where("held_until < ?", Time.current)
            .update_all(status: :available, held_until: nil, booking_id: nil)
  end
end
```

**Adapter: Solid Queue, not Sidekiq.** DB-backed (runs on the MySQL already in the stack per
[[tech-stack]]), no separate Redis service to provision/operate, Rails 8 default from the same
team as Turbo/Stimulus (used here for background jobs only — no Hotwire views, per
[[rails-api-only-vue-spa]]). Native recurring-job support via `config/recurring.yml` covers the
seat-hold sweep directly — run it every minute, no cron/whenever gem needed:

```yaml
# config/recurring.yml
release_expired_seat_holds:
  class: ReleaseExpiredSeatHoldsJob
  schedule: every minute
```

`mission_control-jobs` gives a web dashboard equivalent to Sidekiq Web. GoodJob/Que were ruled
out outright — both Postgres-only, and this stack is MySQL. **RabbitMQ was also considered and
ruled out** — it solves cross-service pub/sub for a microservices architecture; this is a
monolith (Rails API + Vue SPA) with no other service to decouple from, and its job types (a
periodic sweep, later notification sends) need none of that routing machinery. Revisit Solid
Queue itself only if job volume/latency needs genuinely outgrow DB-backed dispatch, which isn't
expected for this product's job types (the hold sweep, and later notification sends per
[[mvp-scope]]).

**How to apply:** default to `perform_later` for anything non-critical-path (once notifications
are built) and for recurring sweeps; keep `perform_now`/inline only for something the response
genuinely depends on (e.g. claiming the seat hold itself, which must complete before checkout
proceeds).
