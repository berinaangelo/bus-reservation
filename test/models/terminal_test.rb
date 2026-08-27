require "test_helper"

class TerminalTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:terminal).valid?
  end

  test "requires a name" do
    terminal = build(:terminal, name: nil)
    assert_not terminal.valid?
    assert_includes terminal.errors[:name], "can't be blank"
  end

  test "requires a city" do
    terminal = build(:terminal, city: nil)
    assert_not terminal.valid?
    assert_includes terminal.errors[:city], "can't be blank"
  end

  test "name is unique" do
    create(:terminal, name: "Cubao")
    dupe = build(:terminal, name: "Cubao")
    assert_not dupe.valid?
    assert_includes dupe.errors[:name], "has already been taken"
  end
end
