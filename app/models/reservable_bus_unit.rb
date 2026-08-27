# Common base for bus classes that use a real seat map (TripSeat rows) instead of the
# ordinary-class seat-count fallback. Not instantiated directly — see AirconBusUnit,
# DeluxeBusUnit, DoubleDeckBusUnit.
class ReservableBusUnit < BusUnit
  validates :seat_layout, presence: true

  def reservable?
    true
  end
end
