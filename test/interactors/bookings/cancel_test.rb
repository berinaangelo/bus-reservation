require "test_helper"

class Bookings::CancelTest < ActiveSupport::TestCase
  test "cancels a reservable-class booking and releases its seats" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    booking = create(:booking, trip: trip)
    trip_seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :booked, booking: booking)
    passenger = create(:passenger, booking: booking, trip_seat: trip_seat)

    result = Bookings::Cancel.call(booking: booking)

    assert result.success?
    assert result.booking.cancelled?
    trip_seat.reload
    assert trip_seat.available?
    assert_nil trip_seat.booking_id
    assert_nil trip_seat.held_until
    assert_nil passenger.reload.trip_seat_id
  end

  test "cancels an ordinary-class booking and gives seats_available back" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 8)
    booking = create(:booking, trip: trip, seat_count: 2)

    result = Bookings::Cancel.call(booking: booking)

    assert result.success?
    assert result.booking.cancelled?
    assert_equal 10, trip.reload.seats_available
  end

  test "cancelling an already-cancelled booking is a no-op success" do
    booking = create(:booking, status: :cancelled)

    result = Bookings::Cancel.call(booking: booking)

    assert result.success?
    assert result.booking.cancelled?
  end

  test "fails for a booking that's no longer confirmed or cancelled" do
    booking = create(:booking, status: :completed)

    result = Bookings::Cancel.call(booking: booking)

    assert result.failure?
    assert_equal "This booking can no longer be cancelled", result.message
  end

  test "a released seat can be reclaimed by a new passenger without a uniqueness collision" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    booking = create(:booking, trip: trip)
    trip_seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :booked, booking: booking)
    create(:passenger, booking: booking, trip_seat: trip_seat)

    Bookings::Cancel.call(booking: booking)

    new_booking = create(:booking, trip: trip)
    new_passenger = build(:passenger, booking: new_booking, trip_seat: trip_seat.reload)
    assert new_passenger.valid?
  end
end
