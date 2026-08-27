require "test_helper"

class TripTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:trip).valid?
  end

  test "requires a route and bus_unit" do
    trip = build(:trip, route: nil, bus_unit: nil)
    assert_not trip.valid?
    assert_includes trip.errors[:route], "must exist"
    assert_includes trip.errors[:bus_unit], "must exist"
  end

  test "arrival_at must be after departure_at" do
    trip = build(:trip, departure_at: 2.days.from_now, arrival_at: 1.day.from_now)
    assert_not trip.valid?
    assert_includes trip.errors[:arrival_at], "must be after departure_at"
  end

  test "status defaults to scheduled and exposes the enum" do
    trip = create(:trip)
    assert trip.scheduled?

    trip.cancelled!
    assert trip.cancelled?
  end

  test "destroying a trip with bookings is restricted" do
    trip = create(:trip)
    create(:booking, trip: trip)

    assert_not trip.destroy
    assert_includes trip.errors[:base], "Cannot delete record because dependent bookings exist"
  end

  test "bus_unit is blocked from an overlapping trip on the same window" do
    bus_unit = create(:aircon_bus_unit)
    create(:trip, bus_unit: bus_unit, departure_at: Time.zone.parse("2026-09-01 08:00"), arrival_at: Time.zone.parse("2026-09-01 12:00"))

    overlapping = build(:trip, bus_unit: bus_unit, departure_at: Time.zone.parse("2026-09-01 10:00"), arrival_at: Time.zone.parse("2026-09-01 14:00"))
    assert_not overlapping.valid?
    assert_includes overlapping.errors[:bus_unit_id], "is already booked for an overlapping trip"
  end

  test "bus_unit overlap ignores cancelled trips" do
    bus_unit = create(:aircon_bus_unit)
    create(:trip, bus_unit: bus_unit, status: :cancelled, departure_at: Time.zone.parse("2026-09-01 08:00"), arrival_at: Time.zone.parse("2026-09-01 12:00"))

    overlapping = build(:trip, bus_unit: bus_unit, departure_at: Time.zone.parse("2026-09-01 10:00"), arrival_at: Time.zone.parse("2026-09-01 14:00"))
    assert overlapping.valid?
  end

  test "bus_unit overlap excludes itself when updating an unrelated attribute" do
    trip = create(:trip)

    trip.status = :boarding
    assert trip.valid?
  end
end
