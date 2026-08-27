require "test_helper"

class TripSeatTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:trip_seat).valid?
  end

  test "a seat can only appear once per trip" do
    trip = create(:trip)
    seat = create(:seat, bus_unit: trip.bus_unit)
    create(:trip_seat, trip: trip, seat: seat)

    dupe = build(:trip_seat, trip: trip, seat: seat)
    assert_not dupe.valid?
    assert_includes dupe.errors[:seat_id], "has already been taken"
  end

  test "bookable scope includes available seats and expired holds, excludes live holds" do
    trip = create(:trip)
    available = create(:trip_seat, trip: trip, status: :available)
    expired_hold = create(:trip_seat, trip: trip, status: :held, held_until: 1.minute.ago)
    live_hold = create(:trip_seat, trip: trip, status: :held, held_until: 1.hour.from_now)
    booked = create(:trip_seat, trip: trip, status: :booked)

    bookable_ids = TripSeat.bookable.pluck(:id)

    assert_includes bookable_ids, available.id
    assert_includes bookable_ids, expired_hold.id
    assert_not_includes bookable_ids, live_hold.id
    assert_not_includes bookable_ids, booked.id
  end

  test "bookable? instance method mirrors the bookable scope" do
    assert build(:trip_seat, status: :available).bookable?
    assert build(:trip_seat, status: :held, held_until: 1.minute.ago).bookable?
    assert_not build(:trip_seat, status: :held, held_until: 1.hour.from_now).bookable?
    assert_not build(:trip_seat, status: :booked).bookable?
  end
end
