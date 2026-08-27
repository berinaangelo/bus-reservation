require "test_helper"

class Bookings::CreateBookingTest < ActiveSupport::TestCase
  test "creates a confirmed booking with seat_count nil for a reservable trip" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    result = call(trip: trip, passengers: [ { full_name: "Grace" }, { full_name: "Bea" } ])

    assert result.success?
    assert result.booking.persisted?
    assert result.booking.confirmed?
    assert_nil result.booking.seat_count
    assert ReferenceCode.valid?(result.booking.reference_code)
  end

  test "sets seat_count to the passenger count for an ordinary trip" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit))

    result = call(trip: trip, passengers: [ { full_name: "Grace" } ])

    assert result.success?
    assert_equal 1, result.booking.seat_count
  end

  test "retries with a fresh reference_code when one collides with an existing booking" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    colliding_code = ReferenceCode.generate
    create(:booking, reference_code: colliding_code)

    fresh_code = ReferenceCode.generate
    result = stub_reference_code_generate([ colliding_code, fresh_code ]) do
      call(trip: trip, passengers: [ { full_name: "Grace" } ])
    end

    assert result.success?
    assert_equal fresh_code, result.booking.reference_code
  end

  test "fails cleanly after exhausting retries when every code collides" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    colliding_code = ReferenceCode.generate
    create(:booking, reference_code: colliding_code)

    result = stub_reference_code_generate([ colliding_code ]) do
      call(trip: trip, passengers: [ { full_name: "Grace" } ])
    end

    assert result.failure?
    assert_equal "Could not generate a unique reference code", result.message
  end

  test "resolves as a replay when a booking with the same idempotency_key already exists" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    existing = create(:booking, idempotency_key: "idem-race")

    result = call(trip: trip, passengers: [ { full_name: "Grace" } ], idempotency_key: "idem-race")

    assert result.success?
    assert_equal existing, result.booking
    assert result.idempotent_replay
    assert_equal 1, Booking.where(idempotency_key: "idem-race").count
  end

  test "fails loudly on an unrelated validation error instead of retrying" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    result = call(trip: trip, passengers: [ { full_name: "Grace" } ], contact_number: nil)

    assert result.failure?
    assert_match(/Contact number/, result.message)
  end

  test "no-ops on replay" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    assert_no_difference "Booking.count" do
      result = call(trip: trip, passengers: [ { full_name: "Grace" } ], idempotent_replay: true)
      assert result.success?
    end
  end

  private

  # Minitest 6 dropped Object#stub; a small manual singleton-method swap does the same job here.
  def stub_reference_code_generate(codes)
    original = ReferenceCode.method(:generate)
    index = 0
    ReferenceCode.define_singleton_method(:generate) do
      value = codes[index] || codes.last
      index += 1
      value
    end
    yield
  ensure
    ReferenceCode.define_singleton_method(:generate, original)
  end

  def call(trip:, passengers:, contact_number: "09171234567", idempotency_key: SecureRandom.hex(8), idempotent_replay: nil)
    Bookings::CreateBooking.call(
      trip: trip,
      contact_number: contact_number,
      idempotency_key: idempotency_key,
      total_amount: 95_000,
      passengers: passengers,
      idempotent_replay: idempotent_replay
    )
  end
end
