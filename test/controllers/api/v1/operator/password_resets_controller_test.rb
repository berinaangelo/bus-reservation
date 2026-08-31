require "test_helper"

class Api::V1::Operator::PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "requesting a reset for a known active email returns the generic message and sends mail" do
    staff = create(:operator_staff, email: "staff@example.com")

    assert_emails 1 do
      assert_difference "PasswordResetToken.count", 1 do
        post api_v1_operator_password_resets_path, params: { email: "staff@example.com" }
      end
    end

    assert_response :ok
    assert_equal "If that email is registered, we've sent password reset instructions.", JSON.parse(response.body)["message"]
    assert_equal staff.id, PasswordResetToken.last.operator_staff_id
  end

  test "requesting a reset for an unknown email returns the identical generic message and sends no mail" do
    assert_no_emails do
      assert_no_difference "PasswordResetToken.count" do
        post api_v1_operator_password_resets_path, params: { email: "nobody@example.com" }
      end
    end

    assert_response :ok
    assert_equal "If that email is registered, we've sent password reset instructions.", JSON.parse(response.body)["message"]
  end

  test "requesting a reset for an inactive staff returns the identical generic message and sends no mail" do
    create(:operator_staff, email: "staff@example.com", active: false)

    assert_no_emails do
      assert_no_difference "PasswordResetToken.count" do
        post api_v1_operator_password_resets_path, params: { email: "staff@example.com" }
      end
    end

    assert_response :ok
    assert_equal "If that email is registered, we've sent password reset instructions.", JSON.parse(response.body)["message"]
  end

  test "requesting a reset with a blank email returns 422" do
    post api_v1_operator_password_resets_path, params: { email: "" }

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"]["email"].present?
  end

  test "confirming with a valid token changes the password, clears lockout, and revokes sessions" do
    staff = create(:operator_staff, password: "oldpassword1", failed_attempts: 3, locked_at: Time.current)
    OperatorSession.issue_for(staff)
    _token, raw_token = PasswordResetToken.issue_for(staff)

    patch api_v1_operator_password_reset_path(raw_token), params: { password: "newpassword1", password_confirmation: "newpassword1" }

    assert_response :ok
    assert_equal "Password updated. You can now log in.", JSON.parse(response.body)["message"]

    staff.reload
    assert staff.authenticate("newpassword1")
    assert_equal 0, staff.failed_attempts
    assert_nil staff.locked_at
    assert_equal 0, staff.operator_sessions.count
    assert_nil PasswordResetToken.authenticate(raw_token)
  end

  test "confirming with an expired or garbage token returns 422" do
    patch api_v1_operator_password_reset_path("not-a-real-token"), params: { password: "newpassword1", password_confirmation: "newpassword1" }

    assert_response :unprocessable_entity
    assert_equal "This reset link is invalid or has expired.", JSON.parse(response.body)["error"]
  end

  test "confirming with a mismatched confirmation returns 422 with field errors" do
    staff = create(:operator_staff)
    _token, raw_token = PasswordResetToken.issue_for(staff)

    patch api_v1_operator_password_reset_path(raw_token), params: { password: "newpassword1", password_confirmation: "different1" }

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"]["password_confirmation"].present?
  end

  test "confirming with a too-short password returns 422 with field errors" do
    staff = create(:operator_staff)
    _token, raw_token = PasswordResetToken.issue_for(staff)

    patch api_v1_operator_password_reset_path(raw_token), params: { password: "short", password_confirmation: "short" }

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"]["password"].present?
  end
end
