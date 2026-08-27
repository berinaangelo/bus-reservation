require "test_helper"

class Payments::SetCollectedTest < ActiveSupport::TestCase
  test "collected: true on a pending_cash payment sets status and collected_at" do
    payment = create(:payment, status: :pending_cash, collected_at: nil)

    result = Payments::SetCollected.call(payment: payment, collected: true)

    assert result.success?
    assert result.payment.collected?
    assert result.payment.collected_at.present?
  end

  test "collected: true on an already-collected payment is a no-op" do
    payment = create(:payment, :collected)
    original_timestamp = payment.collected_at

    result = Payments::SetCollected.call(payment: payment, collected: true)

    assert result.success?
    assert_equal original_timestamp, result.payment.reload.collected_at
  end

  test "collected: false on a collected payment reverts to pending_cash and clears collected_at" do
    payment = create(:payment, :collected)

    result = Payments::SetCollected.call(payment: payment, collected: false)

    assert result.success?
    assert result.payment.pending_cash?
    assert_nil result.payment.collected_at
  end

  test "collected: false on an already-pending_cash payment is a no-op" do
    payment = create(:payment, status: :pending_cash, collected_at: nil)

    result = Payments::SetCollected.call(payment: payment, collected: false)

    assert result.success?
    assert result.payment.pending_cash?
    assert_nil result.payment.collected_at
  end
end
