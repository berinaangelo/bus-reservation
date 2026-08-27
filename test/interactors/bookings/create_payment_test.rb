require "test_helper"

class Bookings::CreatePaymentTest < ActiveSupport::TestCase
  test "creates a pending_cash payment for the booking's total" do
    booking = create(:booking)

    result = Bookings::CreatePayment.call(booking: booking, total_amount: 95_000)

    assert result.success?
    payment = booking.reload.payment
    assert payment.present?
    assert payment.pending_cash?
    assert_equal 95_000, payment.amount
  end

  test "no-ops on replay" do
    booking = create(:booking)

    assert_no_difference "Payment.count" do
      result = Bookings::CreatePayment.call(booking: booking, total_amount: 95_000, idempotent_replay: true)
      assert result.success?
    end
  end
end
