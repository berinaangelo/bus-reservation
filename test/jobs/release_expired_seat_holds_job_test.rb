require "test_helper"

class ReleaseExpiredSeatHoldsJobTest < ActiveSupport::TestCase
  test "releases a held seat whose hold has expired" do
    trip_seat = create(:trip_seat, status: :held, held_until: 1.minute.ago)

    ReleaseExpiredSeatHoldsJob.perform_now

    trip_seat.reload
    assert trip_seat.available?
    assert_nil trip_seat.held_until
    assert_nil trip_seat.booking_id
  end

  test "leaves a live (unexpired) hold untouched" do
    trip_seat = create(:trip_seat, status: :held, held_until: 1.hour.from_now)

    ReleaseExpiredSeatHoldsJob.perform_now

    assert trip_seat.reload.held?
  end

  test "leaves available and booked seats untouched" do
    available = create(:trip_seat, status: :available)
    booking = create(:booking)
    booked = create(:trip_seat, status: :booked, booking: booking)

    ReleaseExpiredSeatHoldsJob.perform_now

    assert available.reload.available?
    assert booked.reload.booked?
  end

  test "is safe to run with nothing to release" do
    assert_nothing_raised { ReleaseExpiredSeatHoldsJob.perform_now }
  end
end
