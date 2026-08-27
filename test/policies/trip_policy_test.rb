require "test_helper"

class TripPolicyTest < ActiveSupport::TestCase
  test "show? and manage_manifest? are true for staff of the trip's own operator" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)

    policy = TripPolicy.new(staff, trip)

    assert policy.show?
    assert policy.manage_manifest?
  end

  test "show? and manage_manifest? are false for staff of a different operator" do
    trip = create(:trip)
    staff = create(:operator_staff)

    policy = TripPolicy.new(staff, trip)

    assert_not policy.show?
    assert_not policy.manage_manifest?
  end

  test "index?, create?, update?, destroy? are true for staff of the trip's own operator" do
    route = create(:route)
    trip = create(:trip, route: route)
    staff = create(:operator_staff, operator: route.operator)

    assert TripPolicy.new(staff, Trip).index?
    assert TripPolicy.new(staff, trip).create?
    assert TripPolicy.new(staff, trip).update?
    assert TripPolicy.new(staff, trip).destroy?
  end

  test "create?, update?, destroy? are false for staff of a different operator" do
    trip = create(:trip)
    staff = create(:operator_staff)

    policy = TripPolicy.new(staff, trip)

    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
