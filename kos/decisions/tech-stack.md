---
title: tech-stack
tags: [bus-reservation, infra]
date: 2026-08-25
---

Backend: Ruby on Rails (API-only, see [[rails-api-only-vue-spa]]). Frontend: Vue. CSS: Tailwind
CSS. DB engine: MySQL. User's explicit choice, not yet scaffolded as of 2026-08-25 (repo was
empty when this KOS was created).

**Rule:** all UI work (mockups included) uses Tailwind utility classes by default. No hardcoded/
custom CSS unless something genuinely can't be expressed in Tailwind for that specific mockup —
the exception is per-case, not a standing pattern.

