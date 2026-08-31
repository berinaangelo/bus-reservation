# Validates a new-password submission for the reset-password confirm step.
class PasswordResetForm
  include ActiveModel::Model

  attr_accessor :password, :password_confirmation

  validates :password, presence: true, length: { minimum: 8 }
  validates :password, confirmation: true
end
