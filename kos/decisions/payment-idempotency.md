---
title: payment-idempotency
tags: [bus-reservation, checkout, payment]
date: 2026-08-25
---

Booking submission must be idempotent — a double-tap on "Confirm Booking" (slow connection,
impatient rider) must not create two Bookings. Apply via an idempotency key on the checkout
endpoint, generated client-side per checkout attempt. Decided up front because retrofitting this
after the fact is much more error-prone than building it in from the first endpoint.

Originally framed around not double-charging a payment gateway; since [[payment-method]] dropped
the checkout payment gate in favor of cash-on-board, the risk this guards against is purely
duplicate Booking/seat-hold rows, not a duplicate charge. The idempotency requirement itself is
unchanged.
