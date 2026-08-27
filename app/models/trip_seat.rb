class TripSeat < ApplicationRecord
  belongs_to :trip
  belongs_to :seat
  belongs_to :booking, optional: true
  has_one :passenger, dependent: :restrict_with_error

  enum :status, { available: 0, held: 1, booked: 2 }

  validates :seat_id, uniqueness: { scope: :trip_id }

  # A seat is bookable if it's available, or held but the hold already expired (the
  # seat-hold sweep hasn't run yet, but the seat shouldn't block a new claim).
  # See kos/decisions/rails-arel-for-complex-queries.md
  scope :bookable, -> {
    t = arel_table
    where(t[:status].eq(statuses[:available]).or(t[:status].eq(statuses[:held]).and(t[:held_until].lt(Time.current))))
  }

  # Instance-level mirror of the `bookable` scope, for checking one already-loaded (and likely
  # locked) row at a time -- see Bookings::ClaimTripSeats, which can't use the class-level scope
  # mid-lock-loop.
  def bookable?
    available? || (held? && held_until.present? && held_until < Time.current)
  end
end
