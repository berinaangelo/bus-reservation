require "test_helper"

class RoutePolicyTest < ActiveSupport::TestCase
  test "index?, show?, create?, update?, destroy? are true for staff of the route's own operator" do
    route = create(:route)
    staff = create(:operator_staff, operator: route.operator)

    assert RoutePolicy.new(staff, Route).index?
    assert RoutePolicy.new(staff, route).show?
    assert RoutePolicy.new(staff, route).create?
    assert RoutePolicy.new(staff, route).update?
    assert RoutePolicy.new(staff, route).destroy?
  end

  test "show?, create?, update?, destroy? are false for staff of a different operator" do
    route = create(:route)
    staff = create(:operator_staff)

    policy = RoutePolicy.new(staff, route)

    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
