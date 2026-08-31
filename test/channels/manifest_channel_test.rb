require "test_helper"

class ManifestChannelTest < ActionCable::Channel::TestCase
  test "subscribes to a trip in the same operator" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    stub_connection(current_operator_staff: staff)

    subscribe(trip_id: trip.id)

    assert subscription.confirmed?
    assert_has_stream_for trip
  end

  test "rejects subscription for a trip belonging to a different operator" do
    trip = create(:trip)
    staff = create(:operator_staff) # different operator
    stub_connection(current_operator_staff: staff)

    subscribe(trip_id: trip.id)

    assert subscription.rejected?
  end

  test "rejects subscription for a nonexistent trip" do
    staff = create(:operator_staff)
    stub_connection(current_operator_staff: staff)

    subscribe(trip_id: -1)

    assert subscription.rejected?
  end
end
