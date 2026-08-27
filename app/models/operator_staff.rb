class OperatorStaff < ApplicationRecord
  self.table_name = "operator_staff"

  has_secure_password

  belongs_to :operator
  has_many :operator_sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # Assumed by the example Pundit policy in kos/decisions/rails-pundit-for-authorization.md
  # (`user.operator_staff?`) -- OperatorStaff is the only Pundit user type in this app.
  def operator_staff?
    true
  end
end
