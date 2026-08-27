class OrdinaryBusUnit < BusUnit
  validates :seat_layout, absence: true
end
