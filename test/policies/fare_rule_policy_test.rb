require "test_helper"

class FareRulePolicyTest < ActiveSupport::TestCase
  test "index?, show?, create?, update?, destroy? are true for staff of the fare_rule's route's own operator" do
    route = create(:route)
    fare_rule = create(:fare_rule, route: route)
    staff = create(:operator_staff, operator: route.operator)

    assert FareRulePolicy.new(staff, FareRule).index?
    assert FareRulePolicy.new(staff, fare_rule).show?
    assert FareRulePolicy.new(staff, fare_rule).create?
    assert FareRulePolicy.new(staff, fare_rule).update?
    assert FareRulePolicy.new(staff, fare_rule).destroy?
  end

  test "show?, create?, update?, destroy? are false for staff of a different operator" do
    fare_rule = create(:fare_rule)
    staff = create(:operator_staff)

    policy = FareRulePolicy.new(staff, fare_rule)

    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
