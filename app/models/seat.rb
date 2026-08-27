class Seat < ApplicationRecord
  belongs_to :bus_unit
  has_many :trip_seats, dependent: :restrict_with_error

  enum :seat_type, { window: 0, aisle: 1 }
  enum :deck, { lower: 0, upper: 1 }

  validates :seat_number, presence: true, uniqueness: { scope: :bus_unit_id }
  validates :seat_type, presence: true
end
