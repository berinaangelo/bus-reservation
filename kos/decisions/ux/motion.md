---
title: motion
tags: [bus-reservation, ux, identity, motion]
date: 2026-08-25
---

Decided: **minimal interactions only** for MVP — no orchestrated animation, no page-transition
choreography, no ambient motion. Motion is limited to short, functional feedback:

- State-change transitions (seat tile available → held → taken, button hover/press, focus rings)
  at a short duration (~150ms) with a simple ease-out — long enough to not feel like a jump cut,
  short enough to stay out of the way of someone tapping through a 60-seat map quickly.
- No scroll-triggered reveals, no elaborate page-load sequences, no decorative motion — consistent
  with the flat, sharp-cornered [[shape-and-surface|shape language]]; this app reads as a utility
  (buy a bus ticket fast), not a showcase.
- `prefers-reduced-motion` respected — transitions drop to instant/near-instant rather than being
  disabled outright, so state changes (a seat going from available to taken under someone else) are
  still perceivable.

**Explicitly not decided here, revisit if it becomes a real UX gap:** whether the seat-hold
countdown timer gets any motion treatment (e.g. a shrinking ring) beyond a plain numeric
countdown — punted since it's a page-level detail for the seat-selection/checkout screens, not a
token-level decision.

See [[shape-and-surface]] for the static half of this same visual language.
