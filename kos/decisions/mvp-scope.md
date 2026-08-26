---
title: mvp-scope
tags: [bus-reservation, scope, ruthless-simplicity]
date: 2026-08-25
---

MVP scope for bus-reservation, after a ruthless-simplicity pass on the rough entity model. See
[PLAN.md](../PLAN.md) for the one-sentence scope and primary flow this supports.

**Kept:** Terminal/Route/Operator/BusUnit, trip search, Seat+TripSeat with hold TTL (reservable
classes), ordinary-class seat-count fallback, FareRule lookup (effective-dated, no history UI),
Booking/BookingSeat/Passenger, cash-on-board Payment record (no checkout gate — see
[[payment-method]]), reference_code+QR e-ticket, guest booking lookup via reference_code+contact
(this is the account system for v1), seat-hold expiry sweep job, OperatorStaff auth+CRUD scoped to
own operator, trip manifest (also where staff mark a booking's cash as collected), simple cancel
(void + release seat, no refund automation).

**Cut for v1, ranked by post-MVP significance** (highest first — build these soonest once
triggered):

1. **Automated refunds / Refund entity** — build once real online payment (GCash/Maya) becomes
   possible ([[payment-method]] is cash-only until KYC/business verification is available). Table
   stakes once real money moves through the app; deferring past that point is a trust/support risk.
2. **SMS/email notifications** — build when real (non-test) bookings start happening. The
   in-session ticket has no fallback if the rider closes the tab.
3. **Route via-stops / multi-leg routes** — build when onboarding an operator whose real route
   needs one (e.g. Manila–Legazpi via Daet). Domain-correctness gap, not a UX nice-to-have.
4. **Rider accounts/login** — build when repeat-booking volume makes "search from scratch every
   time" visibly cost conversions. reference_code+phone already covers guest management.
5. **Operator onboarding/approval admin UI** — build past roughly a dozen operators, once manual
   DB seeding stops scaling.
6. **QR camera-scan check-in** — build if manual reference_code lookup becomes the actual
   bottleneck at a busy terminal counter.
7. **Operator reporting/analytics** — build when operators start asking for it. No rider impact.
8. **Cancellation/fare audit trail** — build on an actual dispute or an LTFRB audit engagement,
   not speculatively.

**Simplifications kept but leaned down:** Passenger capture is full_name per seat only, one
contact_number lives on the Booking (not per passenger); seat selection is one screen that
branches on bus_class (grid vs. counter); multi-seat booking capped at a small fixed max (e.g.
6) to keep validation trivial.
