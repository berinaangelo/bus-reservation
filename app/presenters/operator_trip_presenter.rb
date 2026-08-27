# JSON shape for a Trip on the operator-admin console. Distinct from the rider-facing
# TripPresenter (which computes a fare and omits editable ids) -- this backs an edit form.
class OperatorTripPresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      route_id: route_id,
      bus_unit_id: bus_unit_id,
      departure_at: departure_at.in_time_zone("Asia/Manila").iso8601,
      arrival_at: arrival_at.in_time_zone("Asia/Manila").iso8601,
      status: status,
      bus_class: bus_unit.fare_class,
      plate_number: bus_unit.plate_number,
      route: "#{route.origin_terminal.name} -> #{route.destination_terminal.name}"
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
