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
| Neutral 500 (muted text)       | 160° 8% 40%  | `#5E6E69` | secondary text, placeholders |
| Neutral 100 (surface)          | 150° 20% 96% | `#F3F7F5` | cards, inputs |
| Background                     | 150° 15% 98% | `#F9FBFA` | page background |

**Text-on-accent (decided):** CTA buttons use Neutral 900 `#1E2925` text on the accent fill, not
white — white on `#EE862B` measures 2.60:1, well under AA. Neutral 900 measures 5.78:1.

**Dark mode (decided):** shipping at launch, not deferred. Same hues/saturations as the light
table, lightness inverted for a dark ground rather than picking new hues — exactly the approach
this file originally flagged as the fallback if dark mode was ever wanted.

| Role                          | Hex (dark) | vs. light |
|--------------------------------|-----------|-----------|
| Primary (brand, nav, links)    | `#3FC086` | lighter/brighter for contrast on dark bg |
| Secondary (premium class badge)| `#AC85DB` | lighter/brighter |
| Accent/CTA                     | `#F5A155` | lighter/brighter |
| Success (seat available)       | `#43C88C` | lighter/brighter |
| Warning (seat held/expiring)   | `#F3C233` | lighter/brighter |
| Danger (seat taken/error)      | `#E2585C` | lighter/brighter |
| Text (was Neutral 900)         | `#E7EEEA` | inverted |
| Muted text (was Neutral 500)   | `#93A69E` | inverted |
| Surface (was Neutral 100)      | `#171F17` | inverted |
| Border                         | `#2A362E` | new — flat/[[shape-and-surface\|no-shadow]] design needs a border to separate surfaces since there's no shadow to do it |
| Background                     | `#10160F` | inverted |

**Text-on-accent, dark theme (decided):** same problem as light theme, worse — the lightened
dark-mode accent `#F5A155` measures 2.08:1 with white text. CTA buttons use the dark theme's
Background value `#10160F` as text instead, measuring 8.84:1.

**WCAG AA contrast audit (resolved 2026-08-25):** checked the six most-used pairs against WCAG AA
(4.5:1 body text, 3:1 large/UI text). Two fixes applied above (text-on-accent in both themes,
Neutral 500 darkened 45%→40% lightness — was 4.25:1, now 5.17:1). Danger-on-background (5.32:1)
and dark-theme muted-on-background (7.16:1) already passed, no change. Flagged but not fixed:
Primary green as inline body-sized link text on Background measures 3.82:1 — passes for large/UI
text only, needs its own look before shipping links at body size.

**Open follow-ups, not blockers:**
- Green-as-primary-and-as-"success" is intentional, but double-check it doesn't collide with an
  unrelated success toast appearing on the same screen as the seat map.
- Primary-green body-sized link text (3.82:1) needs a fix — darken, underline, or reserve green
  links for large/UI-sized text only.

See [[mvp-scope]] and [[god-moments]] for the product context this identity serves.
