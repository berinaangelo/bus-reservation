class OperatorStaffMailer < ApplicationMailer
  def password_reset(operator_staff, raw_token)
    @operator_staff = operator_staff
    @reset_url = "#{ENV.fetch('FRONTEND_ORIGIN', 'http://localhost:5173')}/operator/reset-password?token=#{raw_token}"

    mail(to: operator_staff.email, subject: "Reset your Operator Console password")
  end

  # Sent when a staff member is invited by a coworker. Reuses the same "set a new password given a
  # valid token" URL/flow as password_reset -- setting an initial password is the same action.
  def invite(operator_staff, raw_token)
    @operator_staff = operator_staff
    @operator = operator_staff.operator
    @set_password_url = "#{ENV.fetch('FRONTEND_ORIGIN', 'http://localhost:5173')}/operator/reset-password?token=#{raw_token}"

    mail(to: operator_staff.email, subject: "You've been invited to the #{@operator.name} Operator Console")
  end
end
