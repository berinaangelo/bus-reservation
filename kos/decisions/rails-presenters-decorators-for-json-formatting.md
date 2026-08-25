---
title: rails-presenters-decorators-for-json-formatting
tags: [bus-reservation, rails, backend, api]
date: 2026-08-25
---

Renamed from the HRIS-project version of this guideline, which was about view-formatting in
server-rendered ERB. Here, since Rails is API-only ([[rails-api-only-vue-spa]]), the equivalent
concern is formatting logic that would otherwise be duplicated across JSON serializers/
controllers — currency display, timezone conversion, computed labels. Gets a Presenter/Decorator,
not copy-pasted.

**Strongest fit in this project:** [[utc-storage-ph-display]] and [[money-as-minor-units]] both
require a consistent conversion (UTC→Asia/Manila, centavos→peso string) before anything goes into
a JSON response. That belongs in one Presenter, not re-derived per serializer.

```ruby
class TripPresenter < SimpleDelegator
  def departure_at_ph
    departure_at.in_time_zone("Asia/Manila").iso8601
  end

  def fare_display
    format("₱%.2f", base_fare / 100.0)
  end
end
```

**How to apply:** any time the same piece of display-formatting logic (currency/date formatting,
computed labels) would otherwise be copy-pasted into more than one serializer or controller
action, put it in a Presenter/Decorator instead.
