require "test_helper"

class PaymentPolicyTest < ActiveSupport::TestCase
  test "update? is true for staff of the payment's booking's trip's own operator" do
    route = create(:route)
    trip = create(:trip, route: route)
    booking = create(:booking, trip: trip)
    payment = create(:payment, booking: booking)
    staff = create(:operator_staff, operator: route.operator)

    assert PaymentPolicy.new(staff, payment).update?
  end

  test "update? is false for staff of a different operator" do
    payment = create(:payment)
    staff = create(:operator_staff)

    assert_not PaymentPolicy.new(staff, payment).update?
  end
end
