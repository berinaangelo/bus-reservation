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

  test "locked? is false with no locked_at" do
    assert_not build(:operator_staff, locked_at: nil).locked?
  end

  test "locked? is true within the lockout duration" do
    staff = build(:operator_staff, locked_at: 1.minute.ago)
    assert staff.locked?
  end

  test "locked? is false once the lockout duration has elapsed" do
    staff = build(:operator_staff, locked_at: (OperatorStaff::LOCKOUT_DURATION + 1.minute).ago)
    assert_not staff.locked?
  end

  test "register_failed_attempt! increments failed_attempts without locking below the threshold" do
    staff = create(:operator_staff)

    (OperatorStaff::LOCKOUT_THRESHOLD - 1).times { staff.register_failed_attempt! }

    assert_equal OperatorStaff::LOCKOUT_THRESHOLD - 1, staff.failed_attempts
    assert_nil staff.locked_at
    assert_not staff.locked?
  end

  test "register_failed_attempt! locks the account on the threshold-crossing attempt" do
    staff = create(:operator_staff)

    OperatorStaff::LOCKOUT_THRESHOLD.times { staff.register_failed_attempt! }

    assert_equal OperatorStaff::LOCKOUT_THRESHOLD, staff.failed_attempts
    assert staff.locked?
  end

  test "register_failed_attempt! does not extend an already-active lock" do
    staff = create(:operator_staff)
    OperatorStaff::LOCKOUT_THRESHOLD.times { staff.register_failed_attempt! }
    locked_at = staff.locked_at

    travel 1.minute do
      staff.register_failed_attempt!
    end

    assert_equal locked_at, staff.reload.locked_at
  end

  test "register_failed_attempt! auto-clears a stale lock and starts a fresh count" do
    staff = create(:operator_staff, failed_attempts: OperatorStaff::LOCKOUT_THRESHOLD, locked_at: (OperatorStaff::LOCKOUT_DURATION + 1.minute).ago)

    staff.register_failed_attempt!

    assert_equal 1, staff.failed_attempts
    assert_nil staff.locked_at
  end

  test "reset_lockout! clears failed_attempts and locked_at" do
    staff = create(:operator_staff, failed_attempts: 3, locked_at: Time.current)

    staff.reset_lockout!

    assert_equal 0, staff.failed_attempts
    assert_nil staff.locked_at
  end
end
