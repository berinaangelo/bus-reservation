class FareRule < ApplicationRecord
  belongs_to :route

  enum :bus_class, { ordinary: 0, aircon: 1, deluxe: 2, double_deck: 3 }

  validates :base_fare, presence: true, numericality: { greater_than: 0 }
  validates :effective_date, presence: true
end
