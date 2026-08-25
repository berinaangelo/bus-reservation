---
title: seat-hold-ttl
tags: [bus-reservation, data-model, checkout]
date: 2026-08-25
---

TripSeat.held_until defaults to 1 hour from the hold being placed. Admin-configurable, not
hardcoded — controls how long a seat stays locked mid-checkout before the expiry sweep releases
it back to available. See [[mvp-scope]] — the sweep job that acts on this TTL is in scope for
MVP; without it, abandoned checkouts silently strand inventory.

**Mechanism (finalized):** a `SystemSetting` table (key/value, e.g. `key: "seat_hold_ttl_minutes"`,
`value: "60"`) — not a Rails credential or env var, since this is a value that may need tuning
without a deploy. Added to the entity model in [PLAN.md](../PLAN.md). The Interactor step that
claims a hold (see [[rails-thin-controllers-organizer-interactor-pattern]]) reads this value at
claim time rather than hardcoding `10.minutes`/`1.hour`.

**Access (finalized):** admin-only, no platform-admin role/UI built for MVP — same call already
made for [[mvp-scope|Operator onboarding/approval admin UI]] (cut, manual until it needs to
scale). `OperatorStaff` cannot touch this table; it isn't exposed through any operator-facing or
rider-facing endpoint. Edited via Rails console/seed by the platform admin directly. No Pundit
policy needed for it yet — there's no in-app UI surface to authorize against. Revisit only if/
when a real platform-admin role gets built (see the same trigger condition as the operator
onboarding UI in [[mvp-scope]]).
