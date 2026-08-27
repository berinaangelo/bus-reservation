require "test_helper"

class Bookings::FindExistingBookingTest < ActiveSupport::TestCase
  test "sets booking and idempotent_replay when a booking with this key already exists" do
    existing = create(:booking, idempotency_key: "idem-123")

    result = Bookings::FindExistingBooking.call(idempotency_key: "idem-123")

    assert result.success?
    assert_equal existing, result.booking
    assert result.idempotent_replay
  end

  test "leaves context untouched when no booking matches" do
    result = Bookings::FindExistingBooking.call(idempotency_key: "idem-does-not-exist")

    assert result.success?
    assert_nil result.booking
    assert_not result.idempotent_replay
  end
end
