---
title: rails-query-objects-for-reused-queries
tags: [bus-reservation, rails, backend, database]
date: 2026-08-25
---

Once a `.where` chain shows up in more than one place, or gets non-trivial, pull it into a Query
Object rather than repeating the logic inline.

**Canonical case: trip search** — the core flow's first step (see [[../PLAN.md]]), filtering by
origin/destination/date and only returning bookable trips:

```ruby
class TripSearch
  def initialize(origin_terminal_id:, destination_terminal_id:, date:)
    @origin_terminal_id = origin_terminal_id
    @destination_terminal_id = destination_terminal_id
    @date = date
  end

  def call
    Trip.joins(:route)
        .where(routes: { origin_terminal_id: @origin_terminal_id, destination_terminal_id: @destination_terminal_id })
        .where(status: :scheduled)
        .where(departure_at: @date.beginning_of_day..@date.end_of_day)
  end
end
```

Other candidates from the domain: "available seats for a trip," "pending/held TripSeats past
their held_until" (feeds the expiry sweep in [[seat-hold-ttl]]).

**How to apply:** a one-off simple `.where` stays inline. Once the same condition is needed in
two places, or the condition itself is complex enough to deserve a name, extract it.
