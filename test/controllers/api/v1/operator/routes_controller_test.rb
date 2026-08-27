require "test_helper"

class Api::V1::Operator::RoutesControllerTest < ActionDispatch::IntegrationTest
  test "creates a route scoped to the current operator" do
    operator = create(:operator)
    origin = create(:terminal)
    destination = create(:terminal)
    staff = create(:operator_staff, operator: operator)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_routes_path,
      params: { origin_terminal_id: origin.id, destination_terminal_id: destination.id, estimated_duration_minutes: 300 },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal operator.id, body["operator_id"]
  end

  test "returns 422 with structured errors when origin and destination are the same" do
    terminal = create(:terminal)
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_routes_path,
      params: { origin_terminal_id: terminal.id, destination_terminal_id: terminal.id },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"]["destination_terminal_id"], "must differ from origin terminal"
  end

  test "updates a route" do
    route = create(:route)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    patch api_v1_operator_route_path(route), params: { distance_km: 123.45 }, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal "123.45", JSON.parse(response.body)["distance_km"]
  end

  test "destroy cascades to fare_rules but is blocked by dependent trips" do
    route = create(:route)
    create(:fare_rule, route: route)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    delete api_v1_operator_route_path(route), headers: { "Authorization" => "Bearer #{token}" }
    assert_response :no_content

    route2 = create(:route)
    create(:trip, route: route2)
    staff2 = create(:operator_staff, operator: route2.operator)
    _session2, token2 = OperatorSession.issue_for(staff2)

    delete api_v1_operator_route_path(route2), headers: { "Authorization" => "Bearer #{token2}" }
    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"]["base"], "Cannot delete record because dependent trips exist"
  end

  test "index paginates the operator's own routes only" do
    operator = create(:operator)
    create_list(:route, 3, operator: operator)
    create(:route) # different operator
    staff = create(:operator_staff, operator: operator)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_routes_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body["meta"]["count"]
  end

  test "returns 403 for staff of a different operator" do
    route = create(:route)
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_route_path(route), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end

  test "returns 401 without a token" do
    route = create(:route)

    get api_v1_operator_route_path(route)

    assert_response :unauthorized
  end

  test "returns 404 for an unknown route" do
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_route_path(id: -1), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :not_found
  end
end
