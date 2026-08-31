require "test_helper"

class TripSeatAvailabilityTest < ActiveSupport::TestCase
  test "counts bookable trip_seats for a reservable bus unit" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:trip_seat, trip: trip, status: :available)
    create(:trip_seat, trip: trip, status: :available)
    create(:trip_seat, trip: trip, status: :booked)
    create(:trip_seat, trip: trip, status: :held, held_until: 1.hour.from_now) # not bookable yet
    create(:trip_seat, trip: trip, status: :held, held_until: 1.hour.ago) # expired hold, bookable

    result = TripSeatAvailability.new([ trip ]).call

    assert_equal 3, result[trip.id]
  end

  test "uses the seats_available column for a non-reservable (ordinary) bus unit" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 18)

    result = TripSeatAvailability.new([ trip ]).call

    assert_equal 18, result[trip.id]
  end

  test "treats a nil seats_available column as zero for an ordinary bus unit" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: nil)

    result = TripSeatAvailability.new([ trip ]).call

    assert_equal 0, result[trip.id]
  end

  test "computes counts for multiple trips in one batch, mixing reservable and ordinary" do
    reservable_trip = create(:trip, bus_unit: create(:deluxe_bus_unit))
    create(:trip_seat, trip: reservable_trip, status: :available)
    ordinary_trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 7)

    result = TripSeatAvailability.new([ reservable_trip, ordinary_trip ]).call

    assert_equal 1, result[reservable_trip.id]
    assert_equal 7, result[ordinary_trip.id]
  end
end
