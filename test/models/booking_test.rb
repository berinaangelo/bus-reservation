require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "valid factory" do
    assert build(:booking).valid?
  end

  test "reference_code is unique" do
    create(:booking, reference_code: "4XK7QM9")
    dupe = build(:booking, reference_code: "4XK7QM9")
    assert_not dupe.valid?
    assert_includes dupe.errors[:reference_code], "has already been taken"
  end

  test "idempotency_key is unique" do
    create(:booking, idempotency_key: "idem-1")
    dupe = build(:booking, idempotency_key: "idem-1")
    assert_not dupe.valid?
    assert_includes dupe.errors[:idempotency_key], "has already been taken"
  end

  test "requires a contact_number" do
    booking = build(:booking, contact_number: nil)
    assert_not booking.valid?
    assert_includes booking.errors[:contact_number], "can't be blank"
  end

  test "status defaults to confirmed and exposes the enum" do
    booking = create(:booking)
    assert booking.confirmed?
  end

  test "destroying a booking cascades to its passengers and payment" do
    booking = create(:booking)
    passenger = create(:passenger, booking: booking)
    payment = create(:payment, booking: booking)

    booking.destroy

    assert_not Passenger.exists?(passenger.id)
    assert_not Payment.exists?(payment.id)
  end
end
