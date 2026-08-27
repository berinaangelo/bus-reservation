---
title: data-model-schema
tags: [bus-reservation, rails, data-model, database]
date: 2026-08-27
---

The entity sketch in [PLAN.md](../PLAN.md) is now real: 14 migrations
(`db/migrate/20260827100001..100014`) and matching `app/models/*.rb`. This note captures the
schema decisions made translating that rough sketch into Rails, including two places it was
superseded by later UI-mockup decisions.

**Passenger/BookingSeat merged into one `passengers` table.** The original sketch had a separate
`Passenger` (with its own `contact_number`) and a `BookingSeat` join table. The Seat Selection
mockup later decided contact_number is one shared field per booking, not per-passenger — so
`contact_number` now lives on `Booking`, and `passengers` (`booking_id`, `trip_seat_id` nullable,
`full_name`) does the job both old tables would have. `trip_seat_id` is null for
`OrdinaryBusUnit` bookings (no seat rows to attach to) and set for reservable-class bookings.
MySQL unique indexes treat `NULL` as distinct, so a unique index on `trip_seat_id` alone enforces
"one passenger per seat" without needing a partial/conditional index.

**`BusUnit` is STI**, not a `bus_class` enum — the one model in scope with a real behavioral fork:
`OrdinaryBusUnit` (`reservable? # => false`, seat_layout must be absent) vs. `ReservableBusUnit`
(abstract intermediate class; `reservable? # => true`, seat_layout required) →
`AirconBusUnit`/`DeluxeBusUnit`/`DoubleDeckBusUnit`. Only `DoubleDeckBusUnit` overrides `decks`
(`%i[lower upper]` vs. `[nil]`). `FareRule.bus_class` stays a plain enum, independent of this —
it's a rate-card lookup dimension, not a specific vehicle.

**Indexes** follow the actual query shapes already designed: `[status, departure_at]` and
`[departure_at, id]` on `trips` (search filter + keyset pagination tie-breaker, see
[[rails-pagination-and-batch-export-processing]]); `[status, held_until]` on `trip_seats` (the
expiry-sweep job's exact query, [[rails-activejob-solid-queue-for-background-work]]);
`[route_id, bus_class, effective_date]` on `fare_rules` (effective-dated lookup); unique
`reference_code`/`idempotency_key` on `bookings`.

**`on delete` cascade decided per relationship**, not applied uniformly: cascade only where the
child row has no independent value without its parent (`Seat`→`BusUnit`, `FareRule`→`Route`,
`TripSeat`→`Trip`, `Passenger`/`Payment`→`Booking`, `OperatorStaff`→`Operator`); restrict
everywhere real transactional/history value would otherwise vanish silently (`Trip`→`Route`/
`BusUnit`, `Booking`→`Trip`, `Route`→`Operator`/`Terminal`, `BusUnit`→`Operator`,
`TripSeat`→`Seat`, `Passenger`→`TripSeat`). `trip_seats.booking_id` is the one nullify — bookings
are cancelled via `status`, never hard-deleted, so this is a defensive fallback, not the expected
path. `trip_seats.booking_id`'s FK is added in a separate migration
(`AddBookingForeignKeyToTripSeats`) after `bookings` exists, since `trips`→`trip_seats` is created
before `bookings` in dependency order.

**No summary/aggregate table added.** The only sum-aggregate consumer in the entity model —
operator revenue/occupancy reporting — is [[mvp-scope|cut #7]], parked. Every in-scope aggregate
(Trip Manifest's paid/checked-in rollup) is bounded to one trip's seats, not a large-table scan.
Add one (e.g. `operator_daily_revenues`) when reporting is greenlit.

**OperatorStaff auth wired up now**, not deferred — `bcrypt` uncommented in the Gemfile,
`password_digest` + `has_secure_password`, since the login screen was already mocked up
(`operator-login.html`). Table is named `operator_staff` (singular-ish, overridden via
`self.table_name`) because Rails' default pluralization gives the awkward `operator_staffs`.

**Testing**: one `test/models/*_test.rb` + matching `test/factories/*.rb` per model (Minitest +
FactoryBot/Faker per [[rails-testing-minitest-factorybot-faker]]), covering presence/required
associations, every uniqueness constraint above, enum round-trips, the STI behavioral differences,
and the cascade/restrict behavior (e.g. destroying a `Trip` with a `Booking` is rejected).

**How to apply:** this is the ground truth for the schema now — don't re-derive it from
[PLAN.md](../PLAN.md)'s older rough sketch, which is superseded by the two merges/moves above.
Next step is the checkout flow (Form Object + Interactor, see
[[rails-form-objects-for-multi-model-forms]] and
[[rails-thin-controllers-organizer-interactor-pattern]]) and `TripSearch`
([[rails-query-objects-for-reused-queries]]), which can now be built against real models.
