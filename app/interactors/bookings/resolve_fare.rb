# Thin adapter around the ApplicableFareRule query object -- kept separate from the query object
# itself so the fare lookup stays reusable outside the checkout flow (e.g. a future fare-preview
# endpoint shown before the rider commits to checkout).
module Bookings
  class ResolveFare
    include Interactor
    include Bookings::ReplayGuard

    def perform
      fare_rule = ApplicableFareRule.new(trip: context.trip).call
      context.fail!(message: "No fare configured for this route and class") if fare_rule.nil?

      context.fare_rule = fare_rule
      context.total_amount = fare_rule.base_fare * context.passengers.size
    end
  end
end
