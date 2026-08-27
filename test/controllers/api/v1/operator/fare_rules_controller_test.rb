require "test_helper"

class Api::V1::Operator::FareRulesControllerTest < ActionDispatch::IntegrationTest
  test "creates a fare rule for the operator's own route" do
    route = create(:route)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_fare_rules_path,
      params: { route_id: route.id, bus_class: "aircon", base_fare: 95_000, effective_date: Date.current },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :created
    assert_equal route.id, JSON.parse(response.body)["route_id"]
  end

  test "returns 404 when creating against an unknown route" do
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_fare_rules_path,
      params: { route_id: -1, bus_class: "aircon", base_fare: 95_000, effective_date: Date.current },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :not_found
  end

  test "returns 403 when creating against a different operator's route" do
    route = create(:route)
    staff = create(:operator_staff)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_fare_rules_path,
      params: { route_id: route.id, bus_class: "aircon", base_fare: 95_000, effective_date: Date.current },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :forbidden
  end

  test "returns 422 for a non-positive base_fare" do
    route = create(:route)
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    post api_v1_operator_fare_rules_path,
      params: { route_id: route.id, bus_class: "aircon", base_fare: 0, effective_date: Date.current },
      headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unprocessable_entity
  end

  test "updates and destroys a fare rule" do
    fare_rule = create(:fare_rule)
    staff = create(:operator_staff, operator: fare_rule.route.operator)
    _session, token = OperatorSession.issue_for(staff)

    patch api_v1_operator_fare_rule_path(fare_rule), params: { base_fare: 100_000 }, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert_equal 100_000, JSON.parse(response.body)["base_fare"]

    delete api_v1_operator_fare_rule_path(fare_rule), headers: { "Authorization" => "Bearer #{token}" }
    assert_response :no_content
  end

  test "index paginates the operator's own fare rules only" do
    route = create(:route)
    create_list(:fare_rule, 2, route: route)
    create(:fare_rule) # different operator
    staff = create(:operator_staff, operator: route.operator)
    _session, token = OperatorSession.issue_for(staff)

    get api_v1_operator_fare_rules_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal 2, JSON.parse(response.body)["meta"]["count"]
  end

  test "returns 401 without a token" do
    fare_rule = create(:fare_rule)

    get api_v1_operator_fare_rule_path(fare_rule)

    assert_response :unauthorized
  end
end
