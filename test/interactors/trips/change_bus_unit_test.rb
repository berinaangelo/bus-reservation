require "test_helper"

class Trips::ChangeBusUnitTest < ActiveSupport::TestCase
  test "destroys stale trip_seats and regenerates for the new bus_unit" do
    old_bus_unit = create(:aircon_bus_unit)
    create_list(:seat, 2, bus_unit: old_bus_unit)
    trip = create(:trip, bus_unit: old_bus_unit)
    Trips::Schedule.call(trip: trip)
    assert_equal 2, trip.trip_seats.count

    new_bus_unit = create(:aircon_bus_unit)
    create_list(:seat, 4, bus_unit: new_bus_unit)
    trip.bus_unit = new_bus_unit

    result = Trips::ChangeBusUnit.call(trip: trip)

    assert result.success?
    assert_equal 4, trip.trip_seats.reload.count
    assert trip.trip_seats.all? { |ts| ts.seat.bus_unit_id == new_bus_unit.id }
  end

  test "is blocked once a trip_seat already has a real booking" do
    old_bus_unit = create(:aircon_bus_unit)
    seat = create(:seat, bus_unit: old_bus_unit)
    trip = create(:trip, bus_unit: old_bus_unit)
    booking = create(:booking, trip: trip)
    create(:trip_seat, trip: trip, seat: seat, status: :booked, booking: booking)

    trip.bus_unit = create(:aircon_bus_unit)

    result = Trips::ChangeBusUnit.call(trip: trip)

    assert result.failure?
    assert_equal "Cannot change bus unit: this trip already has booked seats", result.message
  end
end
