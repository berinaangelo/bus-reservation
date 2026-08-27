# Validates the shape of a login submission before SessionsController#create checks it against
# real credentials. Deliberately does NOT check whether the email belongs to an OperatorStaff --
# unlike CheckoutForm's trip_exists, surfacing "no such email" here would leak account existence
# through a validation-error channel, contradicting the generic "Incorrect email or password"
# requirement. That check happens in the controller, alongside the password check, so both
# failure modes render identically.
class OperatorLoginForm
  include ActiveModel::Model

  attr_accessor :password
  attr_reader :email

  validates :email, :password, presence: true

  def email=(value)
    @email = value&.strip&.downcase
  end
end
