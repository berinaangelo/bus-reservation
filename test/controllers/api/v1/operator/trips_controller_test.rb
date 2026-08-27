require "test_helper"

class Api::V1::Operator::TripsControllerTest < ActionDispatch::IntegrationTest
  test "create computes arrival_at from the route's estimated_duration_minutes and ignores a submitted arrival_at" do
    route = create(:route, estimated_duration_minutes: 300)
    bus_unit = create(:aircon_bus_unit, operator: route.operator)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)
    departure = 1.day.from_now.change(usec: 0)

    post api_v1_operator_trips_path,
      params: { route_id: route.id, bus_unit_id: bus_unit.id, departure_at: departure, arrival_at: departure + 1.minute },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal (departure + 300.minutes).in_time_zone("Asia/Manila").iso8601, body["arrival_at"]
  end

  test "create returns 422 when the route has no estimated_duration_minutes" do
    route = create(:route, estimated_duration_minutes: nil)
    bus_unit = create(:aircon_bus_unit, operator: route.operator)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_trips_path,
      params: { route_id: route.id, bus_unit_id: bus_unit.id, departure_at: 1.day.from_now },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"]["arrival_at"].join, "estimated_duration_minutes"
  end

  test "create is blocked by a bus_unit double-booking overlap" do
    route = create(:route, estimated_duration_minutes: 240)
    bus_unit = create(:aircon_bus_unit, operator: route.operator)
    create(:trip, route: route, bus_unit: bus_unit, departure_at: Time.zone.parse("2026-09-01 08:00"), arrival_at: Time.zone.parse("2026-09-01 12:00"))
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_trips_path,
      params: { route_id: route.id, bus_unit_id: bus_unit.id, departure_at: Time.zone.parse("2026-09-01 10:00") },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["error"], "already booked for an overlapping trip"
  end

  test "create returns 404 for an unknown route" do
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_trips_path,
      params: { route_id: -1, bus_unit_id: create(:aircon_bus_unit).id, departure_at: 1.day.from_now },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :not_found
  end

  test "changing bus_unit regenerates trip_seats and is blocked once a seat is booked" do
    old_bus_unit = create(:aircon_bus_unit)
    create(:seat, bus_unit: old_bus_unit)
    route = create(:route, estimated_duration_minutes: 200, operator: old_bus_unit.operator)
    trip = create(:trip, route: route, bus_unit: old_bus_unit)
    Trips::Schedule.call(trip: trip)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    new_bus_unit = create(:aircon_bus_unit)
    create_list(:seat, 2, bus_unit: new_bus_unit)

    patch api_v1_operator_trip_path(trip), params: { bus_unit_id: new_bus_unit.id }, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal 2, trip.trip_seats.reload.count

    # now book one of the new seats and try swapping again
    booking = create(:booking, trip: trip)
    trip.trip_seats.first.update!(status: :booked, booking: booking)
    another_bus_unit = create(:aircon_bus_unit)

    patch api_v1_operator_trip_path(trip), params: { bus_unit_id: another_bus_unit.id }, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["error"], "already has booked seats"
  end

  test "destroy is restricted while bookings exist" do
    trip = create(:trip)
    create(:booking, trip: trip)
    staff = create(:operator_staff, operator: trip.route.operator)
    _session, token = OperatorSession.issue_for(staff)

    delete api_v1_operator_trip_path(trip), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
  end

  test "destroy succeeds with no dependent bookings" do
    trip = create(:trip)
    staff = create(:operator_staff, operator: trip.route.operator)
    _session, token = OperatorSession.issue_for(staff)

    delete api_v1_operator_trip_path(trip), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :no_content
  end

  test "returns 403 for staff of a different operator" do
    trip = create(:trip)
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_trip_path(trip), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end

  test "returns 401 without a token" do
    trip = create(:trip)

    get api_v1_operator_trip_path(trip)

    assert_response :unauthorized
  end

  test "index paginates the operator's own trips only" do
    route = create(:route)
    create_list(:trip, 2, route: route)
    create(:trip) # different operator
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_trips_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal 2, JSON.parse(response.body)["meta"]["count"]
  end
end
