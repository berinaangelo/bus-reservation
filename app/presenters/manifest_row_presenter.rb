# JSON shape for one trip-manifest roster row -- wraps a Passenger, not a Booking, so reservable
# and ordinary-class trips render through the same shape (seat_number is nil when there's no
# TripSeat, i.e. ordinary-class -- see kos/decisions/data-model-schema.md, same pattern as
# BookingPresenter#passenger_summary). Nests the parent booking's check-in state and its shared
# Payment (nil-safe, though every confirmed booking has one by the time it reaches this screen).
class ManifestRowPresenter < SimpleDelegator
  def as_json(*)
    {
      passenger_id: id,
      full_name: full_name,
      seat_number: trip_seat&.seat&.seat_number,
      booking: {
        reference_code: ReferenceCode.format(booking.reference_code),
        contact_number: booking.contact_number,
        status: booking.status,
        checked_in: booking.checked_in?,
        checked_in_at: booking.checked_in_at&.in_time_zone("Asia/Manila")&.iso8601
      },
      payment: booking.payment && PaymentPresenter.new(booking.payment)
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
