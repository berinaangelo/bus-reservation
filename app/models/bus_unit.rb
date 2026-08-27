class BusUnit < ApplicationRecord
  belongs_to :operator
  has_many :seats, dependent: :destroy
  has_many :trips, dependent: :restrict_with_error

  validates :plate_number, presence: true, uniqueness: true
  validates :total_seats, presence: true, numericality: { greater_than: 0 }

  # Whether this bus_class uses a seat map (TripSeat rows) vs. a plain seat-count fallback.
  # Overridden by ReservableBusUnit.
  def reservable?
    false
  end

  # Deck labels seats on this bus are laid out across. Overridden by DoubleDeckBusUnit.
  def decks
    [ nil ]
  end
end
