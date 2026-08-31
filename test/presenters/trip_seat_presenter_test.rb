require "test_helper"

class TripSeatPresenterTest < ActiveSupport::TestCase
  test "includes seat number, deck, seat_type, and status" do
    seat = create(:seat, seat_number: "5A", seat_type: :window, deck: :lower)
    trip_seat = create(:trip_seat, seat: seat, status: :held, held_until: 1.hour.from_now)

    json = TripSeatPresenter.new(trip_seat).as_json

    assert_equal trip_seat.id, json[:id]
    assert_equal "5A", json[:seat_number]
    assert_equal "lower", json[:deck]
    assert_equal "window", json[:seat_type]
    assert_equal "held", json[:status]
  end
end
