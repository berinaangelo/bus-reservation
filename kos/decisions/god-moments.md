---
title: god-moments
tags: [bus-reservation, ux, scope]
date: 2026-08-25
---

The peak UX payoff points the plan is optimized around (Peak-End reasoning — the moments that
build trust or get the app recommended), mapped against the primary flow in
[PLAN.md](../PLAN.md):

1. **Live seat map, no signup.** Search → results → an actual seat grid with real-time
   availability, no account wall. The first "this is just better than the terminal" moment, and
   the trust hinge for everything downstream.
2. **Booking the whole family in one pass.** Multi-seat, multi-passenger checkout in a single
   flow — booking-for-family is the PH norm, not the edge case.
3. **Ticket exists the instant the booking is confirmed.** No payment gate to clear first
   ([[payment-method]] — cash collected on board) — QR + reference_code render immediately, no
   "check your email" gap.
4. **Boarding without paper, without a queue.** reference_code/QR gets the rider checked in
   instantly at the terminal counter — the one god moment that happens in the physical world,
   and the one that decides whether they book digitally next time.
5. **Fixing a mistake without a password.** reference_code + phone number gets a guest back into
   their booking, no login to remember.
6. **The manifest fills itself in (operator side).** Staff see bookings land in real time
   instead of a phone log or spreadsheet.

**Decisive two:** #1 (live seat map) earns the first booking; #4 (instant boarding) is the
real-world proof that decides retention. Everything else compounds trust; those two create or
kill it.
