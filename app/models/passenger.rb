class Passenger < ApplicationRecord
  belongs_to :booking
  belongs_to :trip_seat, optional: true

  validates :full_name, presence: true
  validates :trip_seat_id, uniqueness: true, allow_nil: true
end
