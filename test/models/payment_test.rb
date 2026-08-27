require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:payment).valid?
  end

  test "booking_id is unique (one payment per booking)" do
    booking = create(:booking)
    create(:payment, booking: booking)
    dupe = build(:payment, booking: booking)

    assert_not dupe.valid?
    assert_includes dupe.errors[:booking_id], "has already been taken"
  end

  test "status defaults to pending_cash and exposes the enum" do
    payment = create(:payment)
    assert payment.pending_cash?

    payment.collected!
    assert payment.collected?
  end
end
