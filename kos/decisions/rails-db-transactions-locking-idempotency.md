---
title: rails-db-transactions-locking-idempotency
tags: [bus-reservation, rails, backend, database]
date: 2026-08-25
---

Standing DB operation conventions for bus-reservation.

**1. Transactions for multi-step writes, with an Interactor-specific gotcha.** The `interactor`
gem's `.call` (see [[rails-thin-controllers-organizer-interactor-pattern]]) swallows failures into
`context.success?/failure?` without raising — wrapping plain `.call` in
`ActiveRecord::Base.transaction { ... }` will NOT roll back on a failed step, since nothing
raises. Use `.call!` (raises `Interactor::Failure`) inside the transaction block for real
atomicity:

```ruby
ActiveRecord::Base.transaction do
  Bookings::Checkout.call!(booking_params: params, trip_seat_ids: trip_seat_ids)
end
```

An Interactor step's own `rollback` method is for compensating *non-transactional* side effects
(an already-charged payment, an external API call) — not a substitute for wrapping the actual
multi-model write in a real DB transaction.

**2. Pessimistic locking for the seat-hold race** — the actual overselling guardrail flagged in
[[mvp-scope]]. Two riders claiming the same TripSeat at once is a must-not-double-process
operation, not a rare-conflict one, so it's a locking problem, not an optimistic-retry problem:

```ruby
trip_seat.with_lock do
  return context.fail!(message: "Seat no longer available") unless trip_seat.available?
  trip_seat.update!(status: :held, held_until: SystemSetting.seat_hold_ttl_minutes.minutes.from_now)
end
```

Same pattern for the ordinary-class `seats_available` counter — a conditional atomic update, not
a read-then-write:

```ruby
Trip.where(id: trip.id).where("seats_available > 0").update_all("seats_available = seats_available - 1")
```

**3. Optimistic locking (`lock_version`)** for records where a rare concurrent edit should surface
as "someone else changed this," not silently clobber — fits OperatorStaff editing a Trip or
FareRule, where two staff editing the same record at once is unusual but must be caught.

```ruby
# migration: add_column :trips, :lock_version, :integer, default: 0
rescue ActiveRecord::StaleObjectError
  context.fail!(message: "This record was changed by someone else — please retry.")
```

**4. Idempotency — two levels.** DB-level uniqueness constraints prevent accidental duplicates.
For the checkout/payment endpoint specifically, see [[payment-idempotency]] — that's the
pessimistic-locking-shaped case here (two "Pay" submissions for the same checkout attempt must
serialize/dedupe, not both process).

**Why the pessimistic-vs-optimistic split:** must-not-double-process operations (seat claims,
payment submission) get pessimistic locking so the second request waits/no-ops instead of racing;
rare-conflict user-facing edits (staff editing a Trip) get optimistic locking so the user is asked
to retry instead of paying the cost of a lock on every edit.
