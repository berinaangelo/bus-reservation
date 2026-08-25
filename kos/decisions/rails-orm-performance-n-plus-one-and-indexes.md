---
title: rails-orm-performance-n-plus-one-and-indexes
tags: [bus-reservation, rails, backend, performance]
date: 2026-08-25
---

Standing ORM/performance conventions — the same class of pitfalls that shows up in any ORM, so
called out explicitly rather than assumed.

1. **N+1 queries** — `includes`/`preload`/`eager_load` by default on any association touched in
   a loop (e.g. rendering trip search results with each Trip's Route, Operator, and available
   TripSeat count). Use the `bullet` gem in development to catch what's missed.
2. **Missing indexes on foreign keys / hot columns** — `operator_id`, `route_id`, `trip_id`,
   `booking_id`, `status` on `trip_seats` and `bookings`, `reference_code` (unique). Add the
   index in the migration itself, not as an afterthought.
3. **Looped `.save` instead of bulk ops** — `insert_all`/`upsert_all` for batch work (e.g.
   generating all Seat/TripSeat rows when a Trip is scheduled for a reservable bus_class) instead
   of N individual saves triggering N sets of callbacks/queries.
