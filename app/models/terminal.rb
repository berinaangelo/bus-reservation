class Terminal < ApplicationRecord
  has_many :routes_as_origin, class_name: "Route", foreign_key: :origin_terminal_id, inverse_of: :origin_terminal, dependent: :restrict_with_error
  has_many :routes_as_destination, class_name: "Route", foreign_key: :destination_terminal_id, inverse_of: :destination_terminal, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :city, presence: true
end
