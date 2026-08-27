class Trip < ApplicationRecord
  belongs_to :route
  belongs_to :bus_unit
  has_many :trip_seats, dependent: :destroy
  has_many :bookings, dependent: :restrict_with_error

  enum :status, { scheduled: 0, boarding: 1, departed: 2, completed: 3, cancelled: 4 }

  validates :departure_at, presence: true
  validates :arrival_at, presence: true
  validate :arrival_after_departure

  private

  def arrival_after_departure
    return if departure_at.blank? || arrival_at.blank?

    errors.add(:arrival_at, "must be after departure_at") if arrival_at <= departure_at
  end
end
