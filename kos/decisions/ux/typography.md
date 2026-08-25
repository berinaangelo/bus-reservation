---
title: typography
tags: [bus-reservation, ux, identity, typography]
date: 2026-08-25
---

Decided: **Wayfinding Grotesk**, picked from three type-pairing candidates (Wayfinding Grotesk,
Ticket Stub, First Trip).

**Barlow Condensed** (display) + **Barlow** (body/UI) + **IBM Plex Mono** (data — fares, seat
numbers, reference codes, timers). Display and body share one superfamily, so the pairing's
contrast comes from width (condensed vs. regular) rather than from mixing families — guaranteed
coherent, not negotiated. Condensed, tall letterforms read as route-signage/departure-board,
continuing the transit-signage metaphor [[color-scheme|Terminal Signal]] was already built
around. Plex Mono has genuinely distinct glyphs for the [[reference-code-format|reference_code]]'s
remaining easily-confused characters (2/Z, 5/S, 6/G) once 0/O/1/I/L are already excluded by the
format.

All three faces are on Google Fonts — no self-hosting needed.

## Type scale

| Role                     | Size / line-height | Weight |
|--------------------------|---------------------|--------|
| Display (route/fare hero)| 36–44px / 1.0        | 700, Barlow Condensed |
| H2 (section)              | 24px / 1.15          | 600–700, Barlow Condensed |
| Body                       | 16px / 1.55          | 400–500, Barlow |
| Caption / eyebrow label    | 12px / 1.3, uppercase, tracked | 600, Barlow Condensed |
| Data (fares, seats, codes, timers) | 14–16px, tabular-nums | 400–500, IBM Plex Mono |

## Open follow-ups, not blockers

- Condensed display type is for headers and labels only — never body copy, or it reads terse.
- `font-variant-numeric: tabular-nums` is required wherever fares, seat counts, or the countdown
  timer render — not optional.
- Glyph ambiguity for the reference_code checksum charset (2/Z, 5/S, 6/G) hasn't had a dedicated
  check beyond a visual sample in IBM Plex Mono — worth confirming once the checksum algorithm is
  finalized.

See [[color-scheme]] for the paired color identity, [[mvp-scope]] and [[god-moments]] for product
context.
