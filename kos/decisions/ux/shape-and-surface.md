---
title: shape-and-surface
tags: [bus-reservation, ux, identity, shape]
date: 2026-08-25
---

Decided: **sharp corners, flat elevation, filled buttons.**

- **Corners:** sharp — no (or near-zero) border-radius on cards, buttons, inputs, seat tiles.
  Chosen to keep reading as signage/departure-board rather than a generic rounded-card app,
  continuing the metaphor [[color-scheme|Terminal Signal]] and [[typography|Wayfinding Grotesk]]
  are both already built around. Same reasoning as the condensed display type: the metaphor is
  transit signage, and signage doesn't have soft corners.
- **Elevation:** flat — no box-shadow anywhere. Depth/separation between surfaces (a card off the
  page background, a modal off the page) is carried by a border and a flat surface-color step
  (see the `surface` / `border` tokens in [[color-scheme]], including the dark-mode ones added
  specifically because flat design needs a border to do the job a shadow would otherwise do).
- **Buttons:** filled — solid background color, not outline/ghost, as the default button style.
  Outline/ghost can still exist for secondary actions, but the default/primary action anywhere
  (Book Now, Pay, Confirm) is a filled button using the [[color-scheme|accent]] color.

**How to apply:** in Tailwind terms, `rounded-none` (or a 1–2px `rounded-sm` at most) across
components as the base, no `shadow-*` utilities, borders (`border border-border`) for surface
separation instead, and `bg-accent text-white` (or equivalent) as the default button class rather
than `border border-accent text-accent bg-transparent`.

See [[color-scheme]] for the palette these tokens draw from, [[motion]] for the interaction layer
on top of this static shape language.
