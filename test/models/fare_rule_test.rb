require "test_helper"

class FareRuleTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:fare_rule).valid?
  end

  test "requires a positive base_fare" do
    fare_rule = build(:fare_rule, base_fare: 0)
    assert_not fare_rule.valid?
    assert_includes fare_rule.errors[:base_fare], "must be greater than 0"
  end

  test "requires an effective_date" do
    fare_rule = build(:fare_rule, effective_date: nil)
    assert_not fare_rule.valid?
    assert_includes fare_rule.errors[:effective_date], "can't be blank"
  end

  test "bus_class is exposed as an enum" do
    fare_rule = create(:fare_rule, bus_class: :double_deck)
    assert fare_rule.double_deck?
  end

  test "destroying a route cascades to its fare_rules" do
    route = create(:route)
    fare_rule = create(:fare_rule, route: route)

    route.destroy

    assert_not FareRule.exists?(fare_rule.id)
  end
end
