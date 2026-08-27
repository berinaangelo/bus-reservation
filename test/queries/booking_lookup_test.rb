require "test_helper"

class BookingLookupTest < ActiveSupport::TestCase
  test "finds a booking by exact reference_code and contact_number" do
    booking = create(:booking, contact_number: "09171234567")

    found = lookup(reference_code: booking.reference_code, contact_number: "09171234567").call

    assert_equal booking, found
  end

  test "matches regardless of contact_number formatting differences" do
    booking = create(:booking, contact_number: "09171234567")

    found = lookup(reference_code: booking.reference_code, contact_number: "0917 123 4567").call

    assert_equal booking, found
  end

  test "matches a dashed, lowercase reference_code" do
    booking = create(:booking, contact_number: "09171234567")
    dashed_lowercase = ReferenceCode.format(booking.reference_code).downcase

    found = lookup(reference_code: dashed_lowercase, contact_number: "09171234567").call

    assert_equal booking, found
  end

  test "invalid_code? is true for a bad checksum" do
    result = lookup(reference_code: "4XK7QM0", contact_number: "09171234567")

    assert result.invalid_code?
  end

  test "invalid_code? is false for a valid checksum" do
    result = lookup(reference_code: ReferenceCode.generate, contact_number: "09171234567")

    assert_not result.invalid_code?
  end

  test "call returns nil for a valid checksum with no matching booking" do
    found = lookup(reference_code: ReferenceCode.generate, contact_number: "09171234567").call

    assert_nil found
  end

  test "call returns nil when the code matches but contact_number doesn't" do
    booking = create(:booking, contact_number: "09171234567")

    found = lookup(reference_code: booking.reference_code, contact_number: "09990000000").call

    assert_nil found
  end

  private

  def lookup(reference_code:, contact_number:)
    BookingLookup.new(reference_code: reference_code, contact_number: contact_number)
  end
end
