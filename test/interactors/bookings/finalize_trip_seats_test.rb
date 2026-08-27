require "test_helper"

class Bookings::FinalizeTripSeatsTest < ActiveSupport::TestCase
  test "attaches the booking and flips claimed seats to booked" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :held, held_until: 1.hour.from_now)
    booking = create(:booking, trip: trip)

    result = Bookings::FinalizeTripSeats.call(trip: trip, booking: booking, claimed_trip_seats: [ seat ])

    assert result.success?
    seat.reload
    assert seat.booked?
    assert_equal booking, seat.booking
    assert_nil seat.held_until
  end

  test "no-ops for a non-reservable trip" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit))
    booking = create(:booking, trip: trip)

    result = Bookings::FinalizeTripSeats.call(trip: trip, booking: booking, claimed_trip_seats: nil)

    assert result.success?
  end

  test "no-ops on replay" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :held, held_until: 1.hour.from_now)
    booking = create(:booking, trip: trip)

    result = Bookings::FinalizeTripSeats.call(trip: trip, booking: booking, claimed_trip_seats: [ seat ], idempotent_replay: true)

    assert result.success?
    assert seat.reload.held?
  end
end
