require "test_helper"

class Trips::ScheduleTest < ActiveSupport::TestCase
  test "generates a TripSeat per existing Seat for a reservable bus_unit" do
    bus_unit = create(:aircon_bus_unit)
    create_list(:seat, 3, bus_unit: bus_unit)
    trip = build(:trip, bus_unit: bus_unit)

    result = Trips::Schedule.call(trip: trip)

    assert result.success?
    assert_equal 3, trip.trip_seats.count
    assert trip.trip_seats.all?(&:available?)
  end

  test "no-ops for a reservable bus_unit with zero seats" do
    trip = build(:trip, bus_unit: create(:aircon_bus_unit))

    result = Trips::Schedule.call(trip: trip)

    assert result.success?
    assert_equal 0, trip.trip_seats.count
  end

  test "no-ops for an ordinary bus_unit" do
    trip = build(:trip, bus_unit: create(:ordinary_bus_unit))

    result = Trips::Schedule.call(trip: trip)

    assert result.success?
    assert_equal 0, trip.trip_seats.count
  end

  test "fails when the bus_unit already has an overlapping trip" do
    bus_unit = create(:aircon_bus_unit)
    create(:trip, bus_unit: bus_unit, departure_at: Time.zone.parse("2026-09-01 08:00"), arrival_at: Time.zone.parse("2026-09-01 12:00"))
    trip = build(:trip, bus_unit: bus_unit, departure_at: Time.zone.parse("2026-09-01 10:00"), arrival_at: Time.zone.parse("2026-09-01 14:00"))

    result = Trips::Schedule.call(trip: trip)

    assert result.failure?
    assert_includes result.message, "already booked for an overlapping trip"
  end
end
