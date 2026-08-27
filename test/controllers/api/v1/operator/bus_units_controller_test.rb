require "test_helper"

class Api::V1::Operator::BusUnitsControllerTest < ActionDispatch::IntegrationTest
  test "maps bus_class param to the correct STI subclass" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_bus_units_path,
      params: { bus_class: "double_deck", plate_number: "NEW-1", total_seats: 60, seat_layout: { lower: { rows: 9 }, upper: { rows: 9 } } },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "double_deck", body["bus_class"]
    assert_equal "DoubleDeckBusUnit", BusUnit.find(body["id"]).type
  end

  test "creates an ordinary bus unit with no seat_layout" do
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_bus_units_path,
      params: { bus_class: "ordinary", plate_number: "NEW-2", total_seats: 50 },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :created
    assert_not JSON.parse(response.body)["reservable"]
  end

  test "returns 400 for an unknown bus_class" do
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_bus_units_path,
      params: { bus_class: "luxury", plate_number: "X-1", total_seats: 10 },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :bad_request
  end

  test "switching class from reservable to ordinary is rejected" do
    bus_unit = create(:aircon_bus_unit)
    staff = create(:operator_staff, operator: bus_unit.operator)
    _session, token = OperatorSession.issue_for(staff)

    patch api_v1_operator_bus_unit_path(bus_unit), params: { bus_class: "ordinary" }, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"]["seat_layout"], "must be blank"
  end

  test "destroy is restricted while trips exist" do
    bus_unit = create(:aircon_bus_unit)
    create(:trip, bus_unit: bus_unit)
    staff = create(:operator_staff, operator: bus_unit.operator)
    _session, token = OperatorSession.issue_for(staff)

    delete api_v1_operator_bus_unit_path(bus_unit), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
  end

  test "returns 403 for staff of a different operator" do
    bus_unit = create(:aircon_bus_unit)
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_bus_unit_path(bus_unit), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end

  test "returns 401 without a token" do
    bus_unit = create(:aircon_bus_unit)

    get api_v1_operator_bus_unit_path(bus_unit)

    assert_response :unauthorized
  end
end
