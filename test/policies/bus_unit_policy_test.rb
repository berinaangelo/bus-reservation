require "test_helper"

class BusUnitPolicyTest < ActiveSupport::TestCase
  test "index?, show?, create?, update?, destroy? are true for staff of the bus_unit's own operator" do
    bus_unit = create(:aircon_bus_unit)
    staff = create(:operator_staff, operator: bus_unit.operator)

    assert BusUnitPolicy.new(staff, BusUnit).index?
    assert BusUnitPolicy.new(staff, bus_unit).show?
    assert BusUnitPolicy.new(staff, bus_unit).create?
    assert BusUnitPolicy.new(staff, bus_unit).update?
    assert BusUnitPolicy.new(staff, bus_unit).destroy?
  end

  test "show?, create?, update?, destroy? are false for staff of a different operator" do
    bus_unit = create(:aircon_bus_unit)
    staff = create(:operator_staff)

    policy = BusUnitPolicy.new(staff, bus_unit)

    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end
end
