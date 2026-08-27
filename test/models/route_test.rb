require "test_helper"

class RouteTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:route).valid?
  end

  test "requires an operator, origin, and destination" do
    route = build(:route, operator: nil, origin_terminal: nil, destination_terminal: nil)
    assert_not route.valid?
    assert_includes route.errors[:operator], "must exist"
    assert_includes route.errors[:origin_terminal], "must exist"
    assert_includes route.errors[:destination_terminal], "must exist"
  end

  test "origin and destination terminal must differ" do
    terminal = create(:terminal)
    route = build(:route, origin_terminal: terminal, destination_terminal: terminal)
    assert_not route.valid?
    assert_includes route.errors[:destination_terminal_id], "must differ from origin terminal"
  end

  test "operator + origin + destination combination is unique" do
    operator = create(:operator)
    origin = create(:terminal)
    destination = create(:terminal)
    create(:route, operator: operator, origin_terminal: origin, destination_terminal: destination)

    dupe = build(:route, operator: operator, origin_terminal: origin, destination_terminal: destination)
    assert_not dupe.valid?
    assert_includes dupe.errors[:operator_id], "has already been taken"
  end
end
