# Knowledge Base Index — bus-reservation

Last updated: 2026-08-25

## Plan
- [PLAN.md](PLAN.md) — one-sentence scope, primary flow, entity model, links to scope/decisions

## Decisions
- [mvp-scope](decisions/mvp-scope.md) — kept vs cut features (ruthless-simplicity pass), cut list ranked by post-MVP significance
- [god-moments](decisions/god-moments.md) — the UX moments the plan is optimized around
- [tech-stack](decisions/tech-stack.md) — Rails (API-only) + Vue frontend + Tailwind CSS + MySQL
- [money-as-minor-units](decisions/money-as-minor-units.md) — store money as integer centavos, not float
- [utc-storage-ph-display](decisions/utc-storage-ph-display.md) — store UTC, display Asia/Manila
- [seat-hold-ttl](decisions/seat-hold-ttl.md) — default 1hr, stored in a SystemSetting table, admin-only (console/seed, no in-app UI for MVP)
- [reference-code-format](decisions/reference-code-format.md) — 6-char grouped alnum + Luhn mod N checksum, e.g. `4XK-7QM-9`
- [payment-idempotency](decisions/payment-idempotency.md) — idempotency key required on checkout/payment submission
- [rails-api-only-vue-spa](decisions/rails-api-only-vue-spa.md) — Rails is JSON-only, Vue owns the whole UI; no ERB/ViewComponent/Turbo
- [rails-thin-controllers-organizer-interactor-pattern](decisions/rails-thin-controllers-organizer-interactor-pattern.md) — thin controllers + Interactor/Organizer
- [rails-db-transactions-locking-idempotency](decisions/rails-db-transactions-locking-idempotency.md) — transactions, pessimistic lock on seat claims, optimistic lock elsewhere
- [rails-form-objects-for-multi-model-forms](decisions/rails-form-objects-for-multi-model-forms.md) — Form Object for checkout (Booking+Passengers+seats)
- [rails-metaprogramming-for-repetitive-methods](decisions/rails-metaprogramming-for-repetitive-methods.md) — define_method loops for repetitive method sets only
- [rails-orm-performance-n-plus-one-and-indexes](decisions/rails-orm-performance-n-plus-one-and-indexes.md) — eager loading, FK indexes, bulk ops
- [rails-pagination-and-batch-export-processing](decisions/rails-pagination-and-batch-export-processing.md) — Pagy for JSON pagination metadata (page-based by default; cursor/keyset carve-out for trip search results), streaming vs job-based exports
- [rails-presenters-decorators-for-json-formatting](decisions/rails-presenters-decorators-for-json-formatting.md) — Presenter for currency/timezone formatting before JSON output
- [rails-pundit-for-authorization](decisions/rails-pundit-for-authorization.md) — Pundit policies for the operator data boundary
- [rails-query-objects-for-reused-queries](decisions/rails-query-objects-for-reused-queries.md) — Query Object for trip search and other reused conditions
- [rails-routes-split-into-dedicated-files](decisions/rails-routes-split-into-dedicated-files.md) — split routes.rb once an area grows large
- [rails-skinny-models-behavior-in-interactors](decisions/rails-skinny-models-behavior-in-interactors.md) — models stay skinny, behavior lives in Interactors
- [rails-testing-minitest-factorybot-faker](decisions/rails-testing-minitest-factorybot-faker.md) — Minitest + FactoryBot/Faker, one test type per concern
- [rails-arel-for-complex-queries](decisions/rails-arel-for-complex-queries.md) — Arel for boolean composition across columns (e.g. bookable-seat check)
- [rails-callback-objects-for-cache-busting](decisions/rails-callback-objects-for-cache-busting.md) — callback object for cache invalidation, Interactor step for everything else
- [rails-activejob-solid-queue-for-background-work](decisions/rails-activejob-solid-queue-for-background-work.md) — Solid Queue, seat-hold expiry sweep as the direct fit

## UX

- [color-scheme](decisions/ux/color-scheme.md) — Terminal Signal: triadic green/violet/orange, green=primary/available, violet=premium class badge, orange=CTA; dark mode = same hues, inverted lightness
- [typography](decisions/ux/typography.md) — Wayfinding Grotesk: Barlow Condensed (display) + Barlow (body) + IBM Plex Mono (data)
- [iconography](decisions/ux/iconography.md) — three-tier icon system: Lucide (default), Phosphor (seat-map state via weight), Tabler (operator/admin overflow)
- [shape-and-surface](decisions/ux/shape-and-surface.md) — sharp corners, flat elevation (border not shadow), filled buttons by default
- [motion](decisions/ux/motion.md) — minimal interactions only for MVP: short functional transitions, no orchestrated animation
- [platform-mark](decisions/ux/platform-mark.md) — "TS" monogram placeholder wordmark, Barlow Condensed Bold

## Reference

(none yet)
