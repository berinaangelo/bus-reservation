require "test_helper"

class Bookings::CheckInTest < ActiveSupport::TestCase
  test "checks in a confirmed booking" do
    booking = create(:booking, status: :confirmed)

    result = Bookings::CheckIn.call(booking: booking)

    assert result.success?
    assert result.booking.checked_in?
    assert result.booking.checked_in_at.present?
  end

  test "checking in an already-checked-in booking is a no-op success" do
    booking = create(:booking, :checked_in)
    original_timestamp = booking.checked_in_at

    result = Bookings::CheckIn.call(booking: booking)

    assert result.success?
    assert_equal original_timestamp, result.booking.reload.checked_in_at
  end

  test "fails for a cancelled booking" do
    booking = create(:booking, status: :cancelled)

    result = Bookings::CheckIn.call(booking: booking)

    assert result.failure?
    assert_equal "This booking can no longer be checked in", result.message
  end

  test "fails for a no_show booking" do
    booking = create(:booking, status: :no_show)

    result = Bookings::CheckIn.call(booking: booking)

    assert result.failure?
    assert_equal "This booking can no longer be checked in", result.message
  end
end
