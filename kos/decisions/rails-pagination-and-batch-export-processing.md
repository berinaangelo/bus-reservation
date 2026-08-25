---
title: rails-pagination-and-batch-export-processing
tags: [bus-reservation, rails, backend, performance]
date: 2026-08-25
---

Standing conventions for pagination and batch/export processing.

**Pagination gem: Pagy**, not Kaminari — leaner/faster, fits the project's general bias toward
the lighter option (same reasoning as [[rails-activejob-solid-queue-for-background-work|Solid
Queue over Sidekiq]]). Since this is an API-only backend (see [[rails-api-only-vue-spa]]),
Pagy's role is producing pagination metadata for a JSON response, not rendering a Turbo Frame —
there's no server-rendered list view here.

```ruby
class TripsController < ApplicationController
  include Pagy::Method

  def index
    trips = TripSearch.new(search_params).call # filters applied first, see rails-query-objects-for-reused-queries
    @pagy, @trips = pagy(trips)
    render json: { trips: TripSerializer.new(@trips), meta: { page: @pagy.page, pages: @pagy.pages, count: @pagy.count } }
  end
end
```

A sitewide default page size is set once in `config/initializers/pagy.rb`
(`Pagy::OPTIONS[:limit] = 20`) so a plain `pagy(collection)` is enough unless a specific endpoint
needs a different count. Prev/Next UI, "Showing X–Y of Z" text, etc. are Vue's concern on the
frontend — Rails only returns the numeric metadata.

**Batch processing / exports — streaming vs job-based batching, depending on size.** Never load
a full table with `Model.all.each` — always `find_each`/`find_in_batches`/`in_batches`
(batch_size 1000 default) for anything touching a potentially-large table.

- **Streaming** (inline, synchronous) — for exports fast enough to complete within a normal
  request (roughly a few seconds).
- **Query-based batching via a background job** — for genuinely large or slow exports (e.g. an
  operator's full trip/revenue history, once [[mvp-scope|operator reporting]] is built). Use a
  Solid Queue job (per [[rails-activejob-solid-queue-for-background-work]]) that walks the data
  in batches, builds the file, then notifies the user with a download link once done — avoids web
  request timeouts entirely.

**How to decide which:** if it's small/fast enough for a normal request, stream inline for
faster response; if it's a genuinely large report or could run long, push it to a background job
— same threshold logic already used for
[[rails-activejob-solid-queue-for-background-work|what goes through ActiveJob]].
