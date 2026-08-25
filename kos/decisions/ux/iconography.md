---
title: iconography
tags: [bus-reservation, ux, identity, icons]
date: 2026-08-25
---

Decided: three-tier icon system, ranked by role rather than one library for everything —
**Lucide** (default), **Phosphor** (seat-map state), **Tabler** (operator/admin overflow). Picked
from a shortlist of the same three candidates; confirmed as a tiered split rather than collapsing
to Phosphor alone for the whole app.

| Tier | Library | Role | License | Vue package |
|------|---------|------|---------|-------------|
| 01 | Lucide | Default UI icon layer — nav, buttons, form fields, empty states | ISC | `lucide-vue-next` |
| 02 | Phosphor | Seat-map state only | MIT | `phosphor-vue` |
| 03 | Tabler | Operator/admin overflow — icons Lucide doesn't have | MIT | `@tabler/icons-vue` |

**Why not one library:** Lucide's single stroke weight matches [[typography|Barlow]]'s
no-flourish register and its `currentColor` SVGs read Tailwind `text-{color}` classes directly —
best default. Phosphor is the only one of the three with a real weight axis (thin → duotone), so
the *same* armchair glyph carries seat state on the seat map: `weight="regular"` in `success`
green for available, `weight="fill"` in `danger` red for taken, `weight="duotone"` in `secondary`
violet for premium classes — reusing the violet role [[color-scheme|Terminal Signal]] already
reserved for premium/upsell, so seat state reads from icon shape as well as color (useful once
colorblind contrast on a 60-seat map is a real concern). Tabler shares Lucide's 24px/2px stroke
geometry (won't visibly clash if it ever appears near it) but has ~4x the icon count, including
transit-specific glyphs neither Lucide nor Phosphor stock (bus-stop, steering-wheel, route,
engine, luggage) — reach for it only when Lucide lacks the icon, mostly operator-side screens
(fleet/BusUnit type, route editing).

**Rule:** Lucide everywhere by default. Phosphor only on the seat map. Tabler only for the
specific glyph Lucide doesn't have. Never mix Lucide and Tabler stroke icons on the same screen —
pick whichever one already owns that screen.

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: '#27915C', secondary: '#7747AE', accent: '#EE862B',
        success: '#30A66B', warning: '#F0B80F', danger: '#C9262C',
      },
      fontFamily: {
        display: ['"Barlow Condensed"', 'sans-serif'],
        sans: ['"Barlow"', 'sans-serif'],
        mono: ['"IBM Plex Mono"', 'monospace'],
      },
    },
  },
}
```

```vue
<!-- seat map: same glyph, weight = state -->
<PhArmchair weight="regular" class="w-6 h-6 text-success" />  <!-- available -->
<PhArmchair weight="fill"    class="w-6 h-6 text-danger"  />  <!-- taken -->
<PhArmchair weight="duotone" class="w-6 h-6 text-secondary" /> <!-- premium -->
```

See [[color-scheme]] and [[typography]] for the palette and type system this pairs with.
