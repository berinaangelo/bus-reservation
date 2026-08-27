require "test_helper"

class OperatorTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:operator).valid?
  end

  test "requires a name" do
    operator = build(:operator, name: nil)
    assert_not operator.valid?
    assert_includes operator.errors[:name], "can't be blank"
  end

  test "franchise_number is unique" do
    create(:operator, franchise_number: "LTFRB-1")
    dupe = build(:operator, franchise_number: "LTFRB-1")
    assert_not dupe.valid?
    assert_includes dupe.errors[:franchise_number], "has already been taken"
  end

  test "destroying an operator with routes is restricted" do
    operator = create(:operator)
    create(:route, operator: operator)

    assert_not operator.destroy
    assert_includes operator.errors[:base], "Cannot delete record because dependent routes exist"
  end
end
