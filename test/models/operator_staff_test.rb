require "test_helper"

class OperatorStaffTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:operator_staff).valid?
  end

  test "requires an operator" do
    staff = build(:operator_staff, operator: nil)
    assert_not staff.valid?
    assert_includes staff.errors[:operator], "must exist"
  end

  test "email is unique" do
    create(:operator_staff, email: "staff@example.com")
    dupe = build(:operator_staff, email: "staff@example.com")
    assert_not dupe.valid?
    assert_includes dupe.errors[:email], "has already been taken"
  end

  test "authenticates with the correct password via has_secure_password" do
    staff = create(:operator_staff, password: "s3cret123")
    assert staff.authenticate("s3cret123")
    assert_not staff.authenticate("wrong")
  end

  test "destroying an operator cascades to its staff" do
    operator = create(:operator)
    staff = create(:operator_staff, operator: operator)

    operator.destroy

    assert_not OperatorStaff.exists?(staff.id)
  end
end
