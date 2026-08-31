require "test_helper"

class Api::V1::Operator::CheckInsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  test "checks in a confirmed booking by reference_code" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)
    booking = create(:booking, trip: trip, status: :confirmed)
    create(:passenger, booking: booking)

    post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
      params: { reference_code: ReferenceCode.format(booking.reference_code) },
      headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert body["rows"].first["booking"]["checked_in"]
    assert booking.reload.checked_in?
  end

  test "checking in the same booking twice is a no-op success" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)
    booking = create(:booking, trip: trip, status: :confirmed)
    create(:passenger, booking: booking)

    2.times do
      post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
        params: { reference_code: booking.reference_code },
        headers: { "Authorization" => "Bearer #{raw_token}" }
      assert_response :success
    end
  end

  test "returns 422 for an invalid checksum" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
      params: { reference_code: "4XK7QM0" },
      headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :unprocessable_entity
    assert_equal "Invalid reference code", JSON.parse(response.body)["error"]
  end

  test "returns 404 for a valid code that belongs to a different trip" do
    route = create(:route)
    trip = create(:trip, route: route)
    other_booking = create(:booking) # different trip entirely
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
      params: { reference_code: other_booking.reference_code },
      headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :not_found
  end

  test "returns 422 for a cancelled booking" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)
    booking = create(:booking, trip: trip, status: :cancelled)

    post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
      params: { reference_code: booking.reference_code },
      headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :unprocessable_entity
    assert_equal "This booking can no longer be checked in", JSON.parse(response.body)["error"]
  end

  test "returns 401 without a token" do
    trip = create(:trip)

    post api_v1_operator_trip_check_ins_path(trip_id: trip.id), params: { reference_code: "4XK7QM9" }

    assert_response :unauthorized
  end

  test "returns 403 for staff of a different operator" do
    trip = create(:trip)
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
      params: { reference_code: "4XK7QM9" },
      headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :forbidden
  end

  test "broadcasts to the manifest channel on a real check-in" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)
    booking = create(:booking, trip: trip, status: :confirmed)
    create(:passenger, booking: booking)

    assert_broadcast_on(ManifestChannel.broadcasting_for(trip), type: "checked_in") do
      post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
        params: { reference_code: booking.reference_code },
        headers: { "Authorization" => "Bearer #{raw_token}" }
    end
  end

  test "does not broadcast on a no-op re-check-in" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)
    booking = create(:booking, trip: trip, status: :confirmed, checked_in_at: 1.hour.ago)
    create(:passenger, booking: booking)

    assert_no_broadcasts(ManifestChannel.broadcasting_for(trip)) do
      post api_v1_operator_trip_check_ins_path(trip_id: trip.id),
        params: { reference_code: booking.reference_code },
        headers: { "Authorization" => "Bearer #{raw_token}" }
    end
  end
end
