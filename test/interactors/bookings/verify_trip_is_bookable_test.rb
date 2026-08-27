require "test_helper"

class Bookings::VerifyTripIsBookableTest < ActiveSupport::TestCase
  test "succeeds for a scheduled trip" do
    trip = create(:trip, status: :scheduled)

    result = Bookings::VerifyTripIsBookable.call(trip: trip)

    assert result.success?
  end

  test "fails for a trip that isn't scheduled" do
    trip = create(:trip, status: :cancelled)

    result = Bookings::VerifyTripIsBookable.call(trip: trip)

    assert result.failure?
    assert_equal "Trip is no longer open for booking", result.message
  end

  test "picks up a status change made after the context.trip was loaded" do
    trip = create(:trip, status: :scheduled)
    stale_trip = Trip.find(trip.id)
    trip.update!(status: :cancelled)

    result = Bookings::VerifyTripIsBookable.call(trip: stale_trip)

    assert result.failure?
  end

  test "no-ops on replay" do
    trip = create(:trip, status: :cancelled)

    result = Bookings::VerifyTripIsBookable.call(trip: trip, idempotent_replay: true)

    assert result.success?
  end
end
