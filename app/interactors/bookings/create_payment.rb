# Cash-only, no checkout payment gate -- see kos/decisions/payment-method.md. The Booking is
# already `confirmed` by this point; this Payment record just tracks the cash collection that
# happens later at boarding, via the trip-manifest check-in screen.
module Bookings
  class CreatePayment
    include Interactor
    include Bookings::ReplayGuard

    def perform
      Payment.create!(booking: context.booking, amount: context.total_amount, status: :pending_cash)
    end
  end
end
