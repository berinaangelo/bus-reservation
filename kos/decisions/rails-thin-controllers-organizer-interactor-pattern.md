---
title: rails-thin-controllers-organizer-interactor-pattern
tags: [bus-reservation, rails, architecture, backend]
date: 2026-08-25
---

Carried over from the user's own established practice on past Rails projects (see
[[tech-stack]]): thin controllers, single-purpose Interactors, and an Organizer that composes
them into one named flow — using the `interactor` / `interactor-rails` gem convention.

**The shape:**
- **Controller** — stays thin. Calls one Organizer, branches on `result.success?`. No business
  logic in the controller itself — here that means rendering JSON (per
  [[rails-api-only-vue-spa]]), not a redirect/flash.
- **Interactor** — one class, one job (`include Interactor`), reads and writes off a shared
  `context` object, calls `context.fail!(message:)` to halt the chain. Optionally defines
  `rollback` to undo its own effect if a later step in the same organizer fails.
- **Organizer** — `include Interactor::Organizer`, declares the sequence of Interactors via
  `organize A, B, C`. No logic of its own — it's a named, reusable wrapper around "this whole
  flow," not a place business rules live.

**Example — Checkout** (the core flow's payment step, see [[../PLAN.md]]):

```ruby
# app/controllers/bookings_controller.rb
class BookingsController < ApplicationController
  def create
    result = Bookings::Checkout.call(booking_params: booking_params, trip_seat_ids: params[:trip_seat_ids])

    if result.success?
      render json: BookingSerializer.new(result.booking), status: :created
    else
      render json: { error: result.message }, status: :unprocessable_entity
    end
  end
end
```

```ruby
# app/interactors/bookings/checkout.rb
module Bookings
  class Checkout
    include Interactor::Organizer

    organize Bookings::ClaimSeatHolds,
             Bookings::CreateRecord,
             Bookings::AttachPassengers,
             Bookings::ChargePayment
  end
end
```

```ruby
# app/interactors/bookings/claim_seat_holds.rb
module Bookings
  class ClaimSeatHolds
    include Interactor

    def call
      seats = TripSeat.where(id: context.trip_seat_ids, status: :available)
      context.fail!(message: "Seat no longer available") unless seats.count == context.trip_seat_ids.size

      seats.update_all(status: :held, held_until: SystemSetting.seat_hold_ttl_minutes.minutes.from_now)
      context.trip_seats = seats
    end

    # Organizer rolls back completed steps in reverse if a later one fails
    def rollback
      context.trip_seats&.update_all(status: :available, held_until: nil)
    end
  end
end
```

Why this, not ad-hoc service objects with no shared convention: keeps every controller action the
same shape to read (thin, one call, branch on success), and multi-step flows (checkout touches
TripSeat, Booking, Passenger, and Payment in one request) get automatic rollback on partial
failure without hand-rolled transaction/undo logic per feature.
