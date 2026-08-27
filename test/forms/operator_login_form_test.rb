require "test_helper"

class OperatorLoginFormTest < ActiveSupport::TestCase
  test "valid with email and password present" do
    form = OperatorLoginForm.new(email: "staff@example.com", password: "s3cret123")

    assert form.valid?
  end

  test "invalid without email" do
    form = OperatorLoginForm.new(email: nil, password: "s3cret123")

    assert_not form.valid?
    assert_includes form.errors[:email], "can't be blank"
  end

  test "invalid without password" do
    form = OperatorLoginForm.new(email: "staff@example.com", password: nil)

    assert_not form.valid?
    assert_includes form.errors[:password], "can't be blank"
  end

  test "email= strips whitespace and downcases" do
    form = OperatorLoginForm.new(email: " Staff@Example.com ")

    assert_equal "staff@example.com", form.email
  end
end
