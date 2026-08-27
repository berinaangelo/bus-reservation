class OperatorStaff < ApplicationRecord
  self.table_name = "operator_staff"

  has_secure_password

  belongs_to :operator

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
