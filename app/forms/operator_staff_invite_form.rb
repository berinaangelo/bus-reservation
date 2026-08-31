# Validates the shape of an "invite a staff member" submission. Uniqueness/persistence errors
# (e.g. duplicate email) surface separately, from OperatorStaff#save -- this only validates shape,
# same division of labor as PasswordResetRequestForm/OperatorLoginForm.
class OperatorStaffInviteForm
  include ActiveModel::Model

  attr_accessor :name
  attr_reader :email

  validates :name, :email, presence: true

  def email=(value)
    @email = value&.strip&.downcase
  end
end
