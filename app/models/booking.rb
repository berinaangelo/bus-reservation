class Booking < ApplicationRecord
  belongs_to :trip
  has_many :passengers, dependent: :destroy
  has_one :payment, dependent: :destroy
  # No dependent option: bookings are cancelled via status, never destroyed, so a TripSeat's
  # booking_id is only ever nulled out by Bookings::Cancel, not by an AR callback here. See
  # kos/decisions/data-model-schema.md.
  has_many :trip_seats

  enum :status, { confirmed: 0, cancelled: 1, no_show: 2, completed: 3 }

  scope :checked_in, -> { where.not(checked_in_at: nil) }

  validates :reference_code, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :contact_number, presence: true
  validates :idempotency_key, presence: true, uniqueness: true

  def checked_in?
    checked_in_at.present?
  end
end
