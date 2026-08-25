---
title: rails-arel-for-complex-queries
tags: [bus-reservation, rails, backend, database]
date: 2026-08-25
---

Reach for Arel (`Model.arel_table`) once a query outgrows what a plain `.where(...)` hash can
express cleanly — `OR` combinations across columns, date-range overlap checks, dynamic SQL
comparisons. An Arel-built condition typically lives inside a
[[rails-query-objects-for-reused-queries|Query Object]] or a model class method, not inline in a
controller.

**Canonical example for this domain** — a seat is bookable if it's `available`, OR it's `held`
but the hold already expired (the [[seat-hold-ttl]] sweep hasn't run yet, but the seat shouldn't
block a new claim):

```ruby
class TripSeat < ApplicationRecord
  def self.bookable
    t = arel_table
    where(t[:status].eq("available").or(t[:status].eq("held").and(t[:held_until].lt(Time.current))))
  end
end
```

**How to apply:** default to plain ActiveRecord `.where` for simple equality/range conditions;
reach for Arel once the condition needs boolean composition (`.and`/`.or`/`.not`) across columns
or SQL-level comparisons that don't map cleanly to a hash.
