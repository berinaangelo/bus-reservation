require "test_helper"

class Bookings::ResolveFareTest < ActiveSupport::TestCase
  test "sets fare_rule and total_amount from the applicable fare" do
    route = create(:route)
    create(:fare_rule, route: route, bus_class: :aircon, base_fare: 95_000)
    trip = create(:trip, route: route, bus_unit: create(:aircon_bus_unit))
    passengers = [ { full_name: "Grace" }, { full_name: "Bea" } ]

    result = Bookings::ResolveFare.call(trip: trip, passengers: passengers)

    assert result.success?
    assert_equal 190_000, result.total_amount
  end

  test "fails when no fare rule applies" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    result = Bookings::ResolveFare.call(trip: trip, passengers: [ { full_name: "Grace" } ])

    assert result.failure?
    assert_equal "No fare configured for this route and class", result.message
  end

  test "no-ops on replay" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    result = Bookings::ResolveFare.call(trip: trip, passengers: [], idempotent_replay: true)

    assert result.success?
    assert_nil result.total_amount
  end
end
