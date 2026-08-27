# JSON shape for a confirmed booking / e-ticket. See
# kos/decisions/rails-presenters-decorators-for-json-formatting.md.
class BookingPresenter < SimpleDelegator
  def as_json(*)
    {
      reference_code: ReferenceCode.format(reference_code),
      status: status,
      contact_number: contact_number,
      total_amount: total_amount,
      seat_count: seat_count,
      trip: trip_summary,
      passengers: passengers.map { |p| passenger_summary(p) },
      payment_status: payment&.status
    }
  end

  # SimpleDelegator forwards #to_json to the wrapped object via method_missing even when #as_json
  # is overridden here -- without this, `render json:` would silently render the raw Booking
  # instead of this presenter's shape.
  def to_json(*args)
    as_json.to_json(*args)
  end

  private

  def trip_summary
    {
      departure_at: trip.departure_at.in_time_zone("Asia/Manila").iso8601,
      arrival_at: trip.arrival_at.in_time_zone("Asia/Manila").iso8601,
      operator: trip.route.operator.name,
      origin_terminal: trip.route.origin_terminal.name,
      destination_terminal: trip.route.destination_terminal.name
    }
  end

  # trip_seat is nil for ordinary-class bookings, which have no seat map -- see
  # kos/decisions/data-model-schema.md.
  def passenger_summary(passenger)
    {
      full_name: passenger.full_name,
      seat_number: passenger.trip_seat&.seat&.seat_number
    }
  end
end
