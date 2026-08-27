# Flips a Payment between pending_cash and collected -- the trip-manifest "Paid" toggle. Unlike
# Bookings::CheckIn, this is bidirectional (the mockup renders it as a live, re-clickable switch),
# so it takes the desired boolean state rather than always moving one direction. No-ops if the
# payment is already in the target state.
#
# Deliberately doesn't guard against a cancelled booking's payment -- whether cash was physically
# collected is a historical fact independent of a later cancellation, and the manifest roster
# excludes cancelled bookings at the query level anyway, so staff can't reach this through the
# intended UI.
module Payments
  class SetCollected
    include Interactor

    def call
      payment = Payment.lock.find(context.payment.id)
      context.payment = payment

      target_status = context.collected ? "collected" : "pending_cash"
      return if payment.status == target_status

      payment.update!(status: target_status, collected_at: context.collected ? Time.current : nil)
    end
  end
end
