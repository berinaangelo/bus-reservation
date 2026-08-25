---
title: rails-testing-minitest-factorybot-faker
tags: [bus-reservation, rails, backend, testing]
date: 2026-08-25
---

Standing testing conventions.

**Framework: Minitest** — Rails' own built-in default (no RSpec DSL added), fitting the project's
general bias toward built-in defaults over extra gems (same reasoning as
[[rails-activejob-solid-queue-for-background-work|Solid Queue over Sidekiq]]).

**One test type per concern, matching the architecture already locked in:**

1. **Model tests** — `test/models/*_test.rb`, `ActiveSupport::TestCase`. Validations/
   associations/scopes only, kept thin per [[rails-skinny-models-behavior-in-interactors]].
   ```ruby
   class TripTest < ActiveSupport::TestCase
     test "search finds trips on the route and date" do
       trip = trips(:cubao_baguio_tomorrow)
       assert_includes TripSearch.new(origin_terminal_id: trip.route.origin_terminal_id, destination_terminal_id: trip.route.destination_terminal_id, date: trip.departure_at.to_date).call, trip
     end
   end
   ```

2. **Request tests** — `test/controllers/*_test.rb`, `ActionDispatch::IntegrationTest` (hits the
   real JSON API route, asserts on response status/body — this is API-only per
   [[rails-api-only-vue-spa]], so there's no view/redirect to assert against).
   ```ruby
   class BookingsControllerTest < ActionDispatch::IntegrationTest
     test "checkout creates a booking and returns 201" do
       post api_v1_bookings_path, params: { trip_seat_ids: [trip_seats(:available_1).id], passengers: [{ full_name: "Grace Lim" }], contact_number: "09171234567" }
       assert_response :created
     end
   end
   ```

3. **Action tests** (Interactors/Organizers, see
   [[rails-thin-controllers-organizer-interactor-pattern]]) — `test/interactors/**/*_test.rb`,
   plain `ActiveSupport::TestCase` against `.call`. `bin/rails test` picks up any
   `test/**/*_test.rb` automatically, no extra config needed for the custom folder.
   ```ruby
   class Bookings::ClaimSeatHoldsTest < ActiveSupport::TestCase
     test "fails when a seat is already held" do
       result = Bookings::ClaimSeatHolds.call(trip_seat_ids: [trip_seats(:already_held).id])
       assert result.failure?
     end
   end
   ```

**Test data: FactoryBot + Faker.** Chosen over Rails' built-in YAML fixtures — the one place this
diverges from the "built-in default" bias, accepted deliberately for more pleasant/varied test
data given how many trip/booking/passenger records the tests will need.

```ruby
# test/factories/passengers.rb
FactoryBot.define do
  factory :passenger do
    full_name { Faker::Name.name }
    contact_number { Faker::PhoneNumber.cell_phone }
  end
end
```
