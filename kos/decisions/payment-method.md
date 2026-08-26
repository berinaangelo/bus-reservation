---
title: payment-method
tags: [bus-reservation, checkout, payment]
date: 2026-08-26
---

Payment is cash-only for v1, collected on board (or at the terminal counter) — not a real
GCash/Maya integration. Real e-wallet integration needs KYC on the developer's end (proof of a
registered business), which isn't available right now — this isn't a "mock until convenient"
placeholder, it stays cash-only until that prerequisite is met.

**Three options considered for how cash fits the checkout flow:**

1. Pay-at-counter, reservation-only until staff confirms — real-world-accurate to how many PH
   provincial bus lines already work, but delays e-ticket issuance until an in-person step,
   breaking [[god-moments|god moment #3]] (ticket exists the instant the booking is confirmed).
2. Mock-instant "Cash" pretending to be a real gateway charge — keeps the existing checkout-gate
   flow byte-for-byte, but is fiction: nothing is actually collected or tracked.
3. **Drop Payment as a checkout gate entirely** — chosen. Seat Selection → Passenger Details →
   Confirm Booking → e-ticket, with no payment step in between and nothing blocking ticket
   issuance.

**Decision: option 3.** A `Payment` record still exists (`booking_id`, `amount`, `status`,
`collected_at`) but starts at `status: pending_cash` and is not a gate — Booking goes straight to
`confirmed` on submission. Operator staff flip `Payment.status` to `collected` later; that flip
reuses the trip manifest check-in screen (reference_code lookup at boarding) rather than a
separate payment-collection screen — add a "Paid" toggle next to check-in.

Rationale: preserves both decisive god moments (live seat map + instant e-ticket) that option 1
would break, without option 2's fiction of simulating a gateway that doesn't exist. It also gives
operators a real fare-collection record instead of a fake success screen, which is useful input if
[[mvp-scope|cancellation/fare audit trail]] (cut #8) is ever built.

The `provider` field on Payment (`gcash`/`maya`/`mock`) from the original entity sketch is dropped
for v1 — there is exactly one method, cash, so no provider enum is needed. Re-add it if/when real
e-wallet integration becomes possible.

Refunds ([[mvp-scope|cut #1]]) are unaffected by this — still deferred, still tied to a real
payment gateway existing.
