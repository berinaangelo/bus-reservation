---
title: money-as-minor-units
tags: [bus-reservation, data-model, money]
date: 2026-08-25
---

All money fields (FareRule.base_fare, Booking.total_amount, Payment.amount) are stored as
integer minor units (centavos), never float/decimal. Chosen to avoid float rounding errors on a
regulated fare — a mismatch between displayed and charged fare is a compliance problem, not just
a bug.
