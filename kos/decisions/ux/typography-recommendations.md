---
title: typography-recommendations
tags: [bus-reservation, ux, identity, typography]
date: 2026-08-25
---

Not yet decided — three typeface pairings, each a distinct personality, evaluated against what
this UI actually has to set: a route/fare "display" moment, dense body copy, and — the part
generic pairings usually ignore — small, high-stakes data (fares, seat numbers, the
[[reference-code-format|reference_code]], countdown timers) that needs tabular figures and
unambiguous letterforms, not just a nice display face. Color is already decided
([[color-scheme]] — Terminal Signal); all three specimens below use it as-is so the only variable
being judged here is type.

Each option pairs a **display** face, a **body/UI** face, and a **data/mono** face (fares, seat
counts, reference codes, timers — anywhere digits line up in a column, set with tabular figures).

## Option 1 — Wayfinding Grotesk

**Barlow Condensed** (display) + **Barlow** (body/UI) + **IBM Plex Mono** (data)

Same superfamily for display and body — the contrast comes from width (condensed vs. regular),
not from mixing families, so the pairing is guaranteed to feel coherent rather than negotiated.
Condensed, tall letterforms read as route-signage/departure-board, which continues the identity
[[color-scheme]] already set (Terminal Signal was itself framed around a transit-signage
metaphor). Plex Mono has genuinely distinct glyphs for the reference_code's remaining
easily-confused characters (2/Z, 5/S, 6/G) once 0/O/1/I/L are already excluded by the format.

Best fit if: the app should feel efficient and official, like reading a terminal departure board.
Risk: condensed display type can feel terse/institutional if overused outside headers — keep it
to headers and labels, never body copy.

## Option 2 — Ticket Stub

**Bitter** (display, slab serif) + **Work Sans** (body/UI) + **Space Mono** (data)

A slab serif for display is a deliberate nod to the physical object this app replaces — a printed
boarding pass or luggage tag — without going literal/skeuomorphic about it. Work Sans is a
neutral humanist sans that lets the slab keep its personality instead of competing with it. Space
Mono's typewriter cadence reinforces the "ticket" idea specifically where the reference_code and
fare print — it looks stamped, which is the one place in the UI that benefits from that.

Best fit if: the brand should feel like heritage-meets-digital — trustworthy because it echoes
something familiar, not because it's clean and impersonal. Risk: slab serifs set small (fare
tables, seat grids) can feel heavy — reserve Bitter for display sizes only, hand everything below
~18px to Work Sans.

## Option 3 — First Trip

**Baloo 2** (display, rounded) + **Manrope** (body/UI) + **DM Mono** (data)

The softest of the three — rounded terminals on the display face, high-x-height geometric body
face. This is the one aimed squarely at the "no account required" first-time booker: someone
comparing this against a terminal counter or a Facebook-group screenshot booking, where an
official/institutional tone reads as friction, not trust. Common register across consumer apps in
this market. DM Mono is quieter than the other two data faces, keeping "held/available/taken"
labels from feeling alarming.

Best fit if: reducing first-booking anxiety matters more than looking official — closer to a
consumer app than a transit authority. Risk: rounded display faces can undersell the operator-side
UI (staff running manifests, CRUD-ing routes) — consider Manrope alone (no Baloo) for
OperatorStaff screens if this is picked, so back-office tooling doesn't feel infantilized.

## Shared type scale (all three, isolating the type variable)

| Role                     | Size / line-height | Weight |
|--------------------------|---------------------|--------|
| Display (route/fare hero)| 36–44px / 1.0        | 700 |
| H2 (section)              | 24px / 1.15          | 600–700 |
| Body                       | 16px / 1.55          | 400–500 |
| Caption / eyebrow label    | 12px / 1.3, uppercase, tracked | 600 |
| Data (fares, seats, codes, timers) | 14–16px, tabular-nums | 400–500 |

## Notes for whichever gets picked

- All three are on Google Fonts — no self-hosting needed.
- Tabular figures (`font-variant-numeric: tabular-nums`) are required wherever fares, seat
  counts, or the countdown timer render — not optional, since misaligned digits undercut trust
  in exactly the screens that ask someone to pay.
- None of these have been checked against the actual reference_code charset for glyph
  ambiguity beyond a visual skim — worth a dedicated pass once the checksum charset is finalized.
