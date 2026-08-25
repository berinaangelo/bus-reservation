---
title: color-scheme
tags: [bus-reservation, ux, identity, color]
date: 2026-08-25
---

Decided: **Terminal Signal**, picked from three color-theory candidates (analogous blue,
complementary navy/orange, triadic green/violet/orange). Chosen over the blue-primary options
specifically to avoid the default booking/fintech blue that most systems in this space already
use.

Triadic harmony — green (150°), violet (268°), orange (28°), evenly spaced 120° apart. Green is
primary/brand and doubles as the "available" seat state (deliberate reinforcement, not
incidental). Violet is reserved for premium seat classes (deluxe/double-deck badges, upsell) —
this is the harmony's payoff, since the other two options had no distinct third role to give
that. Orange carries all CTAs ("Book Now", "Pay").

| Role                          | H/S/L         | Hex       | Usage |
|--------------------------------|--------------|-----------|-------|
| Primary (brand, nav, links)    | 150° 58% 36% | `#27915C` | header, primary buttons, active nav |
| Secondary (premium class badge)| 268° 42% 48% | `#7747AE` | deluxe/double-deck class tags, upsell |
| Accent/CTA                     | 28° 85% 55%  | `#EE862B` | "Book Now"/"Pay", price |
| Success (seat available)       | 150° 55% 42% | `#30A66B` | available seats — near-identical to primary by design |
| Warning (seat held/expiring)   | 45° 88% 50%  | `#F0B80F` | held seats, countdown timer |
| Danger (seat taken/error)      | 358° 68% 47% | `#C9262C` | taken seats, cancel, form errors |
| Neutral 900 (text)             | 160° 15% 14% | `#1E2925` | body text |
| Neutral 500 (muted text)       | 160° 8% 45%  | `#6A7C76` | secondary text, placeholders |
| Neutral 100 (surface)          | 150° 20% 96% | `#F3F7F5` | cards, inputs |
| Background                     | 150° 15% 98% | `#F9FBFA` | page background |

**Open follow-ups, not blockers:**
- WCAG AA contrast not yet checked — verify accent-on-white button text and neutral-500-on-background
  body text during implementation.
- Dark mode not scoped — if wanted later, derive from the same hue/saturation with inverted
  lightness rather than picking new hues.
- Green-as-primary-and-as-"success" is intentional, but double-check it doesn't collide with an
  unrelated success toast appearing on the same screen as the seat map.

See [[mvp-scope]] and [[god-moments]] for the product context this identity serves.
