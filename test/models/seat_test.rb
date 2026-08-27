require "test_helper"

class SeatTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:seat).valid?
  end

  test "seat_number is unique within a bus_unit" do
    bus_unit = create(:aircon_bus_unit)
    create(:seat, bus_unit: bus_unit, seat_number: "1A")
    dupe = build(:seat, bus_unit: bus_unit, seat_number: "1A")

    assert_not dupe.valid?
    assert_includes dupe.errors[:seat_number], "has already been taken"
  end

  test "the same seat_number is allowed on a different bus_unit" do
    create(:seat, bus_unit: create(:aircon_bus_unit), seat_number: "1A")
    other = build(:seat, bus_unit: create(:aircon_bus_unit), seat_number: "1A")

    assert other.valid?
  end

  test "seat_type and deck are exposed as enums" do
    seat = create(:seat, seat_type: :aisle, deck: :upper)
    assert seat.aisle?
    assert seat.upper?
  end
end
