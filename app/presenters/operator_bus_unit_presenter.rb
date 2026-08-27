# JSON shape for a BusUnit on the operator-admin console.
class OperatorBusUnitPresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      operator_id: operator_id,
      plate_number: plate_number,
      bus_class: fare_class,
      total_seats: total_seats,
      seat_layout: seat_layout,
      active: active,
      reservable: reservable?
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
