require "test_helper"

class Bookings::AttachPassengersTest < ActiveSupport::TestCase
  test "creates one passenger per name, paired by position with claimed trip seats" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    booking = create(:booking, trip: trip)
    seat_a = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))
    seat_b = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))

    result = Bookings::AttachPassengers.call(
      booking: booking,
      passengers: [ { full_name: "Grace" }, { full_name: "Bea" } ],
      claimed_trip_seats: [ seat_a, seat_b ]
    )

    assert result.success?
    assert_equal 2, booking.passengers.count
    assert_equal seat_a, booking.passengers.find_by(full_name: "Grace").trip_seat
    assert_equal seat_b, booking.passengers.find_by(full_name: "Bea").trip_seat
  end

  test "leaves trip_seat nil when there are no claimed trip seats (ordinary trip)" do
    booking = create(:booking)

    result = Bookings::AttachPassengers.call(booking: booking, passengers: [ { full_name: "Grace" } ], claimed_trip_seats: nil)

    assert result.success?
    assert_nil booking.passengers.sole.trip_seat
  end

  test "no-ops on replay" do
    booking = create(:booking)

    assert_no_difference "Passenger.count" do
      result = Bookings::AttachPassengers.call(booking: booking, passengers: [ { full_name: "Grace" } ], idempotent_replay: true)
      assert result.success?
    end
  end
end
