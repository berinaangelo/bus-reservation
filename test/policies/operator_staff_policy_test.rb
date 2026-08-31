require "test_helper"

class OperatorStaffPolicyTest < ActiveSupport::TestCase
  test "index?, create? are true for any active staff" do
    staff = create(:operator_staff)

    assert OperatorStaffPolicy.new(staff, OperatorStaff).index?
    assert OperatorStaffPolicy.new(staff, OperatorStaff).create?
  end

  test "show?, update? are true for staff of the same operator" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)
    coworker = create(:operator_staff, operator: operator)

    assert OperatorStaffPolicy.new(staff, coworker).show?
    assert OperatorStaffPolicy.new(staff, coworker).update?
  end

  test "show?, update? are false for staff of a different operator" do
    staff = create(:operator_staff)
    other = create(:operator_staff)

    policy = OperatorStaffPolicy.new(staff, other)

    assert_not policy.show?
    assert_not policy.update?
  end

  test "Scope resolves to only the user's own operator's staff" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)
    coworker = create(:operator_staff, operator: operator)
    other_operator_staff = create(:operator_staff)

    scope = OperatorStaffPolicy::Scope.new(staff, OperatorStaff.all).resolve

    assert_includes scope, staff
    assert_includes scope, coworker
    assert_not_includes scope, other_operator_staff
  end
end
