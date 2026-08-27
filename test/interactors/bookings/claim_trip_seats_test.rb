require "test_helper"

class Bookings::ClaimTripSeatsTest < ActiveSupport::TestCase
  setup do
    @trip = create(:trip, bus_unit: create(:aircon_bus_unit))
  end

  test "claims all requested seats as held with no booking_id yet" do
    seat_a = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit))
    seat_b = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit))

    result = call(trip_seat_ids: [ seat_a.id, seat_b.id ])

    assert result.success?
    assert_equal [ seat_a.id, seat_b.id ].sort, result.claimed_trip_seats.map(&:id).sort
    [ seat_a, seat_b ].each do |seat|
      seat.reload
      assert seat.held?
      assert_nil seat.booking_id
      assert seat.held_until.present?
    end
  end

  test "fails if a requested id doesn't belong to this trip" do
    other_trip_seat = create(:trip_seat)

    result = call(trip_seat_ids: [ other_trip_seat.id ])

    assert result.failure?
    assert_equal "Seat no longer available", result.message
  end

  test "fails if a requested seat is already booked" do
    booked = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit), status: :booked)

    result = call(trip_seat_ids: [ booked.id ])

    assert result.failure?
  end

  test "fails if a requested seat has a live unexpired hold" do
    held = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit), status: :held, held_until: 1.hour.from_now)

    result = call(trip_seat_ids: [ held.id ])

    assert result.failure?
  end

  test "succeeds reclaiming a seat whose hold already expired" do
    expired = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit), status: :held, held_until: 1.minute.ago)

    result = call(trip_seat_ids: [ expired.id ])

    assert result.success?
    assert expired.reload.held?
  end

  test "honors a custom SystemSetting TTL and falls back to 60 minutes when none exists" do
    seat = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit))
    create(:system_setting, key: "seat_hold_ttl_minutes", value: "5")

    result = call(trip_seat_ids: [ seat.id ])

    assert result.success?
    assert_in_delta 5.minutes.from_now, seat.reload.held_until, 5.seconds
  end

  test "falls back to 60 minutes with no SystemSetting row" do
    seat = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit))

    result = call(trip_seat_ids: [ seat.id ])

    assert result.success?
    assert_in_delta 60.minutes.from_now, seat.reload.held_until, 5.seconds
  end

  test "no-ops on replay" do
    seat = create(:trip_seat, trip: @trip, seat: create(:seat, bus_unit: @trip.bus_unit))

    result = call(trip_seat_ids: [ seat.id ], idempotent_replay: true)

    assert result.success?
    assert seat.reload.available?
  end

  test "no-ops for a non-reservable (ordinary) trip" do
    ordinary_trip = create(:trip, bus_unit: create(:ordinary_bus_unit))

    result = Bookings::ClaimTripSeats.call(trip: ordinary_trip, trip_seat_ids: nil)

    assert result.success?
  end

  private

  def call(trip_seat_ids:, idempotent_replay: nil)
    Bookings::ClaimTripSeats.call(trip: @trip, trip_seat_ids: trip_seat_ids, idempotent_replay: idempotent_replay)
  end
end
