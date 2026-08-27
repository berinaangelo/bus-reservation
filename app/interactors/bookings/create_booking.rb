# The idempotency mutex for the whole checkout: rather than trusting a racy "does this key
# already exist?" read, this step just attempts the insert and lets Booking's own uniqueness
# validations (or, in the narrow true-concurrent case, the DB's unique index directly) decide who
# wins a double-submit. This must run BEFORE any seat/capacity claiming (see Bookings::Checkout)
# -- otherwise two simultaneous requests with the same key could both claim inventory before
# either commits, and nothing would ever give the loser's claim back.
module Bookings
  class CreateBooking
    include Interactor
    include Bookings::ReplayGuard

    MAX_ATTEMPTS = 5

    def perform
      MAX_ATTEMPTS.times do
        booking = Booking.new(attributes)

        if save_booking(booking)
          context.booking = booking
          return
        end

        if booking.errors[:idempotency_key].any?
          return if resolve_as_replay
          next # the locking read below somehow found nothing; retry rather than get stuck
        elsif booking.errors[:reference_code].any?
          next # collision against an existing code: retry with a freshly generated one
        else
          context.fail!(message: booking.errors.full_messages.to_sentence)
        end
      end

      context.fail!(message: "Could not generate a unique reference code")
    end

    private

    # Booking's own `uniqueness: true` validations catch an ordinary collision (against an
    # already-committed row) as a validation failure (booking.errors gets populated, save
    # returns false). A true concurrent double-submit -- where a sibling transaction commits the
    # same idempotency_key between our validation SELECT and our INSERT -- bypasses that
    # validation and hits the DB's unique index directly, raising RecordNotUnique instead. Both
    # are surfaced the same way: as an :idempotency_key error on `booking`.
    def save_booking(booking)
      booking.save
    rescue ActiveRecord::RecordNotUnique
      booking.errors.add(:idempotency_key, :taken)
      false
    end

    # A locking read, not a plain one: under MySQL's default REPEATABLE READ isolation, a plain
    # SELECT inside this already-open transaction can miss a row another transaction just
    # committed. `.lock.find_by` (SELECT ... FOR UPDATE) always reads the latest committed data.
    def resolve_as_replay
      existing = Booking.lock.find_by(idempotency_key: context.idempotency_key)
      return false if existing.nil?

      context.booking = existing
      context.idempotent_replay = true
      true
    end

    def attributes
      {
        trip: context.trip,
        contact_number: context.contact_number,
        idempotency_key: context.idempotency_key,
        reference_code: ReferenceCode.generate,
        status: :confirmed,
        total_amount: context.total_amount,
        seat_count: context.trip.bus_unit.reservable? ? nil : context.passengers.size
      }
    end
  end
end
