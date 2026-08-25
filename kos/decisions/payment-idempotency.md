---
title: payment-idempotency
tags: [bus-reservation, checkout, payment]
date: 2026-08-25
---

Booking/payment submission must be idempotent — a double-tap on "Pay" (slow connection, impatient
rider) must not create two Bookings or charge twice. Apply via an idempotency key on the
checkout/payment endpoint, generated client-side per checkout attempt. Decided up front because
retrofitting this after the payment integration exists is much more error-prone than building it
in from the first endpoint.
