# Releases TripSeats stuck `held` past their TTL back to `available` -- an abandoned checkout
# would otherwise strand that seat forever. See kos/decisions/seat-hold-ttl.md and
# kos/decisions/rails-activejob-solid-queue-for-background-work.md. Scheduled every minute via
# config/recurring.yml.
class ReleaseExpiredSeatHoldsJob < ApplicationJob
  def perform
    TripSeat.stale_hold.update_all(status: :available, held_until: nil, booking_id: nil)
  end
end
