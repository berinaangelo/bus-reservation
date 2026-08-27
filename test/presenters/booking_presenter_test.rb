require "test_helper"

class BookingPresenterTest < ActiveSupport::TestCase
  test "formats reference_code with dashes and includes trip/passenger/payment details" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    booking = create(:booking, trip: trip, total_amount: 190_000, seat_count: nil)
    trip_seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit, seat_number: "5A"), status: :booked, booking: booking)
    create(:passenger, booking: booking, full_name: "Grace Lim", trip_seat: trip_seat)
    create(:payment, booking: booking, status: :pending_cash)

    json = BookingPresenter.new(booking).as_json

    assert_equal ReferenceCode.format(booking.reference_code), json[:reference_code]
    assert_includes json[:reference_code], "-"
    assert_equal "confirmed", json[:status]
    assert_equal 190_000, json[:total_amount]
    assert_nil json[:seat_count]
    assert_equal trip.route.operator.name, json[:trip][:operator]
    assert_equal [ { full_name: "Grace Lim", seat_number: "5A" } ], json[:passengers]
    assert_equal "pending_cash", json[:payment_status]
  end

  test "passenger seat_number is nil for an ordinary-class booking" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit))
    booking = create(:booking, trip: trip, seat_count: 1)
    create(:passenger, booking: booking, full_name: "Grace Lim", trip_seat: nil)

    json = BookingPresenter.new(booking).as_json

    assert_equal [ { full_name: "Grace Lim", seat_number: nil } ], json[:passengers]
    assert_equal 1, json[:seat_count]
  end

  test "payment_status is nil when there's no payment yet" do
    booking = create(:booking)

    json = BookingPresenter.new(booking).as_json

    assert_nil json[:payment_status]
  end
end
