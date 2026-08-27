class Trip < ApplicationRecord
  belongs_to :route
  belongs_to :bus_unit
  has_many :trip_seats, dependent: :destroy
  has_many :bookings, dependent: :restrict_with_error

  enum :status, { scheduled: 0, boarding: 1, departed: 2, completed: 3, cancelled: 4 }

  validates :departure_at, presence: true
  validates :arrival_at, presence: true
  validate :arrival_after_departure
  validate :bus_unit_not_double_booked

  private

  def arrival_after_departure
    return if departure_at.blank? || arrival_at.blank?

    errors.add(:arrival_at, "must be after departure_at") if arrival_at <= departure_at
  end

  # overlap: existing.departure_at < new.arrival_at AND existing.arrival_at > new.departure_at,
  # excluding cancelled trips and excluding self on update (where.not(id: id) renders
  # `id IS NOT NULL` when id is nil/new-record, matching everything, which is what we want).
  def bus_unit_not_double_booked
    return if bus_unit_id.blank? || departure_at.blank? || arrival_at.blank?

    overlapping = Trip.where(bus_unit_id: bus_unit_id)
                       .where.not(status: :cancelled)
                       .where.not(id: id)
                       .where("departure_at < ? AND arrival_at > ?", arrival_at, departure_at)

    errors.add(:bus_unit_id, "is already booked for an overlapping trip") if overlapping.exists?
  end
end
