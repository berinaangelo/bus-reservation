require "test_helper"

class SystemSettingTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:system_setting).valid?
  end

  test "key is unique" do
    create(:system_setting, key: "seat_hold_ttl_minutes")
    dupe = build(:system_setting, key: "seat_hold_ttl_minutes")
    assert_not dupe.valid?
    assert_includes dupe.errors[:key], "has already been taken"
  end

  test "requires a value" do
    setting = build(:system_setting, value: nil)
    assert_not setting.valid?
    assert_includes setting.errors[:value], "can't be blank"
  end

  test "seat_hold_ttl_minutes reads the configured value" do
    create(:system_setting, key: "seat_hold_ttl_minutes", value: "90")
    assert_equal 90, SystemSetting.seat_hold_ttl_minutes
  end

  test "seat_hold_ttl_minutes falls back to 60 when unset" do
    assert_equal 60, SystemSetting.seat_hold_ttl_minutes
  end
end
