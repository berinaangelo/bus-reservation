# Bus Reservation — Plan

Status: planning complete, scaffolding not started (as of 2026-08-25).

## One-sentence scope

A rider searches for a bus trip between two terminals, books and pays for a seat, and gets a
QR ticket to board with — no account required.

## Primary flow

1. Rider searches trips by origin, destination, date.
2. Rider picks a trip (operator, class, fare, departure time).
3. Rider selects seat(s) — seat map for aircon/deluxe/double-deck, seat count for ordinary —
   and enters passenger name(s) + one contact number.
4. Rider confirms the booking (cash-on-board — no payment gate, see [[payment-method]]).
5. Rider gets an e-ticket: QR + reference_code, issued immediately on confirmation.
6. Rider looks up or cancels the booking later via reference_code + contact number.

Operator staff exist to make step 1 possible: CRUD their own Route/Trip/BusUnit/FareRule, view
the trip manifest at boarding. Same story, other side of the same flow — not a bolted-on panel.

## Entity model (rough, framework-agnostic)

- **Operator** — the bus liner. name, franchise_number (LTFRB), logo, contact_info, active.
- **Terminal** — a physical place (Cubao, PITX, Alabang…), shared across operators. name,
  city/province, address.
- **Route** — an operator's origin→destination pair. operator_id, origin_terminal_id,
  destination_terminal_id, distance_km, estimated_duration_minutes.
- **BusUnit** (the vehicle) — operator_id, plate_number, bus_class (ordinary / aircon / deluxe /
  double_deck), total_seats, seat_layout (json; null for ordinary — no seat map applies).
- **Seat** — belongs to BusUnit. seat_number, seat_type (window/aisle), deck. Template layout,
  not per-trip state.
- **Trip** — one scheduled departure. route_id, bus_unit_id, departure_at, arrival_at
  (estimated), status (scheduled/boarding/departed/completed/cancelled).
- **TripSeat** — join between Trip and Seat, per-departure state: status
  (available/held/booked), held_until (short-TTL lock during checkout), booking_id. Only
  populated for reservable classes; ordinary trips use a running seats_available counter
  instead.
- **FareRule** — regulated fare matrix, not dynamic pricing. route_id, bus_class, base_fare,
  effective_date. Versioned by effective date, looked up not computed.
- **Passenger** — rider details captured at booking time (full_name, contact_number), separate
  from User because booking-for-someone-else is the PH norm.
- **Booking** — trip_id, user_id (nullable — guest checkout), reference_code (shows on the
  e-ticket/QR for terminal boarding), status (confirmed/cancelled/no_show/completed) — confirmed
  immediately on submission, no pending_payment state (see [[payment-method]]), total_amount.
- **BookingSeat** — join between Booking and TripSeat + Passenger. For ordinary trips this
  collapses to a seat_count on Booking, no seat rows.
- **Payment** — booking_id, amount, status (pending_cash/collected), collected_at. Cash-only for
  v1, not a checkout gate — see [[payment-method]].
- **User** — rider account. Cut from MVP scope (see [[mvp-scope]]) — reference_code + contact
  number lookup covers guest booking management instead.
- **OperatorStaff** — admin accounts scoped to one operator, managing their own trips/fares.
- **SystemSetting** — platform-wide key/value config, admin-only (Rails console/seed for MVP, no
  in-app admin UI/role — see [[seat-hold-ttl]]). First use: `seat_hold_ttl_minutes`.

## MVP scope

See [[mvp-scope]] for the full kept/cut breakdown (ruthless-simplicity pass) and the ranked
post-MVP list. See [[god-moments]] for the UX moments the plan is optimized around.

## Decisions

- [[tech-stack]] — Rails backend + Vue frontend + Tailwind CSS (utility classes only, no hardcoded CSS unless a mockup genuinely needs it)
- [[money-as-minor-units]] — integer centavos, not float
- [[utc-storage-ph-display]] — store UTC, display Asia/Manila
- [[seat-hold-ttl]] — default 1 hour, admin-configurable system setting
- [[reference-code-format]] — 6-char grouped alnum + checksum, e.g. `4XK-7QM-9`
- [[payment-method]] — cash-only, collected on board; no checkout payment gate
- [[payment-idempotency]] — idempotency key required on checkout submission

**Rails engineering guidelines** (carried over/adapted from the user's HRIS project, see
`decisions/rails-*.md` and [[rails-api-only-vue-spa]] for the one adaptation that mattered —
API-only Rails, no server-rendered views): organizer/interactor pattern, DB transactions/
locking/idempotency, form objects, query objects, Arel, ORM performance, pagination/exports,
JSON-formatting presenters, Pundit authorization, callback objects, ActiveJob/Solid Queue,
metaprogramming, route file splitting, skinny models, testing conventions. Full list in
[INDEX.md](INDEX.md).

## Next step

**Data layer done (2026-08-27)** — migrations + models for the entities above are built and
tested; see [[data-model-schema]] for what changed translating this rough sketch into Rails (the
`Passenger`/`BookingSeat` merge, `BusUnit` STI, index/cascade decisions). That note is now the
ground truth for the schema, not this section.

Next: build the checkout flow (Form Object + Interactor) and `TripSearch` against the real
models, then the Vue frontend consuming them.
