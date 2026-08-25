---
title: rails-form-objects-for-multi-model-forms
tags: [bus-reservation, rails, backend, architecture]
date: 2026-08-25
---

A form/request that touches more than one model gets a Form Object — a PORO (Plain Old Ruby
Object) including `ActiveModel::Model` — instead of `accepts_nested_attributes_for` sprawl.

**Canonical case: Checkout** (see [[../PLAN.md]]) touches the Booking record, one or more
Passengers, and the TripSeat claims in one submit.

```ruby
class CheckoutForm
  include ActiveModel::Model

  attr_accessor :trip_seat_ids, :contact_number, :passengers # array of {full_name:}

  validates :trip_seat_ids, :contact_number, presence: true
  validate :passenger_count_matches_seat_count

  private

  def passenger_count_matches_seat_count
    errors.add(:passengers, "must match seat count") if passengers&.size != trip_seat_ids&.size
  end
end
```

The Form Object validates/shapes the input; an Interactor (see
[[rails-thin-controllers-organizer-interactor-pattern]]) does the actual persisting across
models.

**How to apply:** single-model forms (e.g. an OperatorStaff editing one FareRule) just use the
model directly, same as normal Rails. Reach for a Form Object once a request's fields don't map
1:1 onto one AR model.
