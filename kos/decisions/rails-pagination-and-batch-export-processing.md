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

**Trip search results is a carve-out: cursor (keyset) pagination, not page-based.** Use Pagy's
`pagy_keyset` extra instead of plain `pagy()` for the `TripsController#index` endpoint the
[[../decisions/ux/mockups/trip-search-results.html|Trip Search Results]] mockups render. Reasons:

- Trip search is a live, volatile list — trips can be added/cancelled and seat availability
  shifts between page loads (especially near the [[seat-hold-ttl|seat-hold TTL]] boundary).
  Offset pagination risks skipped or duplicated rows if the underlying result set changes mid-
  browse; keyset pagination doesn't have this problem since each page is fetched relative to the
  last row seen, not a row-count offset.
- The rider's actual pattern is "show me more/later trips," never "jump to page 7" — no product
  need for random page access or an exact total count, which is exactly cursor pagination's
  trade-off (no cheap total count, but no `OFFSET` scan cost either as the table grows).

Keyset ordering is `(departure_at, id)` ascending (id as tie-breaker for same-minute departures).
Response shape differs from the page-based one above — no `page`/`pages`, just a cursor token and
a boolean:

```ruby
def index
  trips = TripSearch.new(search_params).call
  @pagy, @trips = pagy_keyset(trips)
  render json: { trips: TripSerializer.new(@trips), meta: { next_cursor: @pagy.next, has_more: !@pagy.next.nil? } }
end
```

Frontend renders this as a "Load more trips" button appending to the existing list, not numbered
pages. Plain page-based `pagy()` stays the default everywhere else (operator trip/booking admin
lists, manifest) where jump-to-page and an exact count are actually useful.

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
