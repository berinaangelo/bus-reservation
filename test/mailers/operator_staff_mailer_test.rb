require "test_helper"

class OperatorStaffMailerTest < ActionMailer::TestCase
  test "password_reset delivers to the staff's email with the reset link" do
    staff = create(:operator_staff, email: "staff@example.com")

    mail = OperatorStaffMailer.password_reset(staff, "raw-reset-token")

    assert_equal [ "staff@example.com" ], mail.to
    assert_equal "Reset your Operator Console password", mail.subject
    assert_match "raw-reset-token", mail.text_part.body.to_s
    assert_match "raw-reset-token", mail.html_part.body.to_s
  end

  test "password_reset builds the reset url against FRONTEND_ORIGIN" do
    staff = create(:operator_staff)

    mail = OperatorStaffMailer.password_reset(staff, "raw-reset-token")

    assert_match %r{\Ahttp://localhost:5173/operator/reset-password\?token=raw-reset-token\z}, mail.text_part.body.to_s[%r{https?://\S+}]
  end

  test "invite delivers to the invited staff's email with the operator name and set-password link" do
    operator = create(:operator, name: "Sunrise Bus Lines")
    staff = create(:operator_staff, operator: operator, email: "newhire@example.com")

    mail = OperatorStaffMailer.invite(staff, "raw-invite-token")

    assert_equal [ "newhire@example.com" ], mail.to
    assert_equal "You've been invited to the Sunrise Bus Lines Operator Console", mail.subject
    assert_match "raw-invite-token", mail.text_part.body.to_s
    assert_match "raw-invite-token", mail.html_part.body.to_s
    assert_match %r{\Ahttp://localhost:5173/operator/reset-password\?token=raw-invite-token\z}, mail.text_part.body.to_s[%r{https?://\S+}]
  end
end
