# JSON shape for a FareRule on the operator-admin console.
class OperatorFareRulePresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      route_id: route_id,
      bus_class: bus_class,
      base_fare: base_fare,
      effective_date: effective_date.iso8601 # a date column -- no timezone conversion needed
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
