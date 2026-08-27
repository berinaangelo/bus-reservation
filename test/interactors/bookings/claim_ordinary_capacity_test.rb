require "test_helper"

class Bookings::ClaimOrdinaryCapacityTest < ActiveSupport::TestCase
  test "decrements seats_available by the passenger count" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 10)

    result = call(trip: trip, passengers: [ { full_name: "A" }, { full_name: "B" } ])

    assert result.success?
    assert_equal 8, trip.reload.seats_available
  end

  test "fails without decrementing when there isn't enough capacity" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 1)

    result = call(trip: trip, passengers: [ { full_name: "A" }, { full_name: "B" } ])

    assert result.failure?
    assert_equal "Not enough seats available", result.message
    assert_equal 1, trip.reload.seats_available
  end

  test "fails when seats_available is nil (uninitialized)" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: nil)

    result = call(trip: trip, passengers: [ { full_name: "A" } ])

    assert result.failure?
  end

  test "no-ops for a reservable trip" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    result = call(trip: trip, passengers: [ { full_name: "A" } ])

    assert result.success?
  end

  test "no-ops on replay" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 10)

    result = call(trip: trip, passengers: [ { full_name: "A" } ], idempotent_replay: true)

    assert result.success?
    assert_equal 10, trip.reload.seats_available
  end

  private

  def call(trip:, passengers:, idempotent_replay: nil)
    Bookings::ClaimOrdinaryCapacity.call(trip: trip, passengers: passengers, idempotent_replay: idempotent_replay)
  end
end
