# JSON shape for a Route on the operator-admin console. Unlike the rider-facing presenters, this
# includes raw editable fields (ids) since it backs an edit form, not just a display. See
# kos/decisions/rails-presenters-decorators-for-json-formatting.md.
class OperatorRoutePresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      operator_id: operator_id,
      origin_terminal_id: origin_terminal_id,
      destination_terminal_id: destination_terminal_id,
      origin_terminal: origin_terminal.name,
      destination_terminal: destination_terminal.name,
      distance_km: distance_km,
      estimated_duration_minutes: estimated_duration_minutes
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
