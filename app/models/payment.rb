class Payment < ApplicationRecord
  belongs_to :booking

  enum :status, { pending_cash: 0, collected: 1 }

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :booking_id, uniqueness: true
end
