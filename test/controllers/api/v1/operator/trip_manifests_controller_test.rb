require "test_helper"

class Api::V1::Operator::TripManifestsControllerTest < ActionDispatch::IntegrationTest
  test "shows the roster and summary for a reservable-class trip" do
    route = create(:route)
    trip = create(:trip, route: route, bus_unit: create(:aircon_bus_unit))
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    seat = create(:seat, bus_unit: trip.bus_unit)
    trip_seat = create(:trip_seat, trip: trip, seat: seat, status: :booked)
    booking = create(:booking, :checked_in, trip: trip)
    trip_seat.update!(booking: booking)
    create(:passenger, booking: booking, trip_seat: trip_seat, full_name: "Grace Lim")
    create(:payment, :collected, booking: booking)

    create(:booking, trip: trip, status: :cancelled) # must not appear

    get api_v1_operator_trip_manifest_path(trip_id: trip.id), headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["summary"]["total_passengers"]
    assert_equal 1, body["summary"]["checked_in"]
    assert_equal 1, body["summary"]["paid"]
    assert_equal 1, body["summary"]["seats_booked"]
    assert_equal 45, body["summary"]["total_seats"]
    assert_equal "scheduled", body["summary"]["trip_status"]

    row = body["rows"].first
    assert_equal "Grace Lim", row["full_name"]
    assert_equal seat.seat_number, row["seat_number"]
    assert row["booking"]["checked_in"]
    assert_equal "collected", row["payment"]["status"]
  end

  test "shows a flat roster (nil seat_number) for an ordinary-class trip" do
    route = create(:route)
    trip = create(:trip, route: route, bus_unit: create(:ordinary_bus_unit), seats_available: 8)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    booking = create(:booking, trip: trip, seat_count: 2)
    create(:passenger, booking: booking, full_name: "Bea Santos")

    get api_v1_operator_trip_manifest_path(trip_id: trip.id), headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["rows"].first["seat_number"]
    assert_equal 42, body["summary"]["seats_booked"] # 50 total - 8 available
  end

  test "returns 401 without a token" do
    trip = create(:trip)

    get api_v1_operator_trip_manifest_path(trip_id: trip.id)

    assert_response :unauthorized
  end

  test "returns 403 for staff of a different operator" do
    trip = create(:trip)
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    get api_v1_operator_trip_manifest_path(trip_id: trip.id), headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :forbidden
  end

  test "returns 404 for an unknown trip" do
    staff = create(:operator_staff)
    _session, raw_token = OperatorSession.issue_for(staff)

    get api_v1_operator_trip_manifest_path(trip_id: -1), headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :not_found
  end

  test "paginates with more than 20 passengers" do
    route = create(:route)
    trip = create(:trip, route: route, bus_unit: create(:ordinary_bus_unit), seats_available: 0)
    staff = create(:operator_staff, operator: route.operator)
    _session, raw_token = OperatorSession.issue_for(staff)

    25.times { create(:passenger, booking: create(:booking, trip: trip)) }

    get api_v1_operator_trip_manifest_path(trip_id: trip.id), headers: { "Authorization" => "Bearer #{raw_token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 20, body["rows"].size
    assert_equal 25, body["meta"]["count"]
    assert_equal 2, body["meta"]["pages"]
  end
end
