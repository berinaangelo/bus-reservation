require "test_helper"

class BusUnitTest < ActiveSupport::TestCase
  test "ordinary bus unit is not reservable and has no seat_layout" do
    bus_unit = build(:ordinary_bus_unit)
    assert bus_unit.valid?
    assert_not bus_unit.reservable?
    assert_equal [ nil ], bus_unit.decks
  end

  test "ordinary bus unit rejects a seat_layout" do
    bus_unit = build(:ordinary_bus_unit, seat_layout: { rows: 10 })
    assert_not bus_unit.valid?
    assert_includes bus_unit.errors[:seat_layout], "must be blank"
  end

  test "aircon and deluxe bus units are reservable and require a seat_layout" do
    %i[aircon_bus_unit deluxe_bus_unit].each do |factory_name|
      reservable = build(factory_name)
      assert reservable.valid?, reservable.errors.full_messages.to_sentence
      assert reservable.reservable?
      assert_equal [ nil ], reservable.decks

      without_layout = build(factory_name, seat_layout: nil)
      assert_not without_layout.valid?
      assert_includes without_layout.errors[:seat_layout], "can't be blank"
    end
  end

  test "double deck bus unit is reservable and exposes both decks" do
    bus_unit = build(:double_deck_bus_unit)
    assert bus_unit.valid?
    assert bus_unit.reservable?
    assert_equal %i[lower upper], bus_unit.decks
  end

  test "plate_number is unique across bus_class types" do
    create(:aircon_bus_unit, plate_number: "NCR-1234")
    dupe = build(:deluxe_bus_unit, plate_number: "NCR-1234")
    assert_not dupe.valid?
    assert_includes dupe.errors[:plate_number], "has already been taken"
  end

  test "destroying a bus_unit with trips is restricted" do
    bus_unit = create(:aircon_bus_unit)
    create(:trip, bus_unit: bus_unit)

    assert_not bus_unit.destroy
    assert_includes bus_unit.errors[:base], "Cannot delete record because dependent trips exist"
  end
end
