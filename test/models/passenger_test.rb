require "test_helper"

class PassengerTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:passenger).valid?
  end

  test "requires a full_name" do
    passenger = build(:passenger, full_name: nil)
    assert_not passenger.valid?
    assert_includes passenger.errors[:full_name], "can't be blank"
  end

  test "trip_seat_id is unique when present, but multiple nils are allowed (ordinary-class bookings)" do
    trip_seat = create(:trip_seat)
    create(:passenger, trip_seat: trip_seat)
    dupe = build(:passenger, trip_seat: trip_seat)
    assert_not dupe.valid?
    assert_includes dupe.errors[:trip_seat_id], "has already been taken"

    assert build(:passenger, trip_seat: nil).valid?
    assert build(:passenger, trip_seat: nil).valid?
  end
end
