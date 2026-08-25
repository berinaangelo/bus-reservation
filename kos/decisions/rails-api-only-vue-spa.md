---
title: rails-api-only-vue-spa
tags: [bus-reservation, rails, architecture, frontend]
date: 2026-08-25
---

Rails runs API-only (JSON), Vue owns the entire UI as a separate frontend — not the
Rails+Hotwire/Turbo pattern used on the user's other current Rails project (HRIS). No ERB views,
no ViewComponent, no Turbo Frames on this project; ignore any Rails guideline that assumes
server-rendered views.

**Why:** [[tech-stack]] already committed to Vue as the frontend before any Rails guideline was
carried over — a hybrid (Rails views + Vue islands) would mean maintaining two rendering
approaches for no benefit here, unlike a project that started server-rendered and added Vue for
specific interactive spots.

**How to apply:** anything view/rendering-specific from a server-rendered Rails project (badge
components, layout shells, Turbo Frame swapping) doesn't transfer — the equivalent concern lives
in Vue instead, out of scope for this KOS's Rails guidelines. Rails-side concerns that don't care
about the rendering layer (interactors, query objects, form objects, authorization, background
jobs, testing, DB conventions) transfer as-is — see the rest of `decisions/rails-*.md`.
