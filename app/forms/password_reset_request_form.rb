# Validates the shape of a "forgot password" submission. Deliberately does NOT check whether the
# email belongs to an OperatorStaff -- same non-enumeration reasoning as OperatorLoginForm. The
# controller always responds with the same generic message regardless of whether the email exists.
class PasswordResetRequestForm
  include ActiveModel::Model

  attr_reader :email

  validates :email, presence: true

  def email=(value)
    @email = value&.strip&.downcase
  end
end
