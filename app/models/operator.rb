class Operator < ApplicationRecord
  has_many :operator_staff, dependent: :destroy
  has_many :routes, dependent: :restrict_with_error
  has_many :bus_units, dependent: :restrict_with_error

  validates :name, presence: true
  validates :franchise_number, presence: true, uniqueness: true
end
