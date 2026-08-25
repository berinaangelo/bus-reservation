---
title: utc-storage-ph-display
tags: [bus-reservation, data-model, time]
date: 2026-08-25
---

All timestamps (Trip.departure_at, Trip.arrival_at, TripSeat.held_until, Payment.paid_at, etc.)
are stored in the DB as UTC. Displayed to users in Asia/Manila time. Decided up front because
retrofitting timezone handling after trip data exists means a data migration, not just a display
change.
