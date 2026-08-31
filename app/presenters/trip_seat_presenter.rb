# JSON shape for one seat in a trip's seat map, used by Seat Selection to render the grid. See
# kos/decisions/rails-presenters-decorators-for-json-formatting.md.
class TripSeatPresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      seat_number: seat.seat_number,
      deck: seat.deck,
      seat_type: seat.seat_type,
      status: status
    }
  end

  # SimpleDelegator forwards #to_json to the wrapped object via method_missing even when #as_json
  # is overridden here -- without this, `render json:` would silently render the raw TripSeat
  # instead of this presenter's shape.
  def to_json(*args)
    as_json.to_json(*args)
  end
end
