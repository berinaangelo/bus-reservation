class Booking < ApplicationRecord
  belongs_to :trip
  has_many :passengers, dependent: :destroy
  has_one :payment, dependent: :destroy

  enum :status, { confirmed: 0, cancelled: 1, no_show: 2, completed: 3 }

  validates :reference_code, presence: true, uniqueness: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :contact_number, presence: true
  validates :idempotency_key, presence: true, uniqueness: true
end
