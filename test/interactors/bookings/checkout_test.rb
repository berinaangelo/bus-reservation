require "test_helper"

class Bookings::CheckoutTest < ActiveSupport::TestCase
  test "happy path for a reservable-class trip" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    seat_a = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))
    seat_b = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))

    result = checkout(
      trip: trip,
      trip_seat_ids: [ seat_a.id, seat_b.id ],
      passengers: [ { full_name: "Grace" }, { full_name: "Bea" } ]
    )

    assert result.success?, result.message
    booking = result.booking
    assert booking.confirmed?
    assert_equal 190_000, booking.total_amount
    assert_nil booking.seat_count
    assert ReferenceCode.valid?(booking.reference_code)
    assert_equal 2, booking.passengers.count
    assert booking.payment.pending_cash?
    [ seat_a, seat_b ].each { |s| assert s.reload.booked? }
    assert_equal [ seat_a, seat_b ].map(&:id).sort, booking.passengers.map { |p| p.trip_seat_id }.sort
  end

  test "happy path for an ordinary-class trip" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 20)
    create(:fare_rule, route: trip.route, bus_class: :ordinary, base_fare: 40_000)

    result = checkout(trip: trip, trip_seat_ids: nil, passengers: [ { full_name: "Grace" } ])

    assert result.success?, result.message
    assert_equal 19, trip.reload.seats_available
    assert_equal 1, result.booking.seat_count
    assert_equal 0, TripSeat.where(trip: trip).count
  end

  test "an idempotent replay returns the same booking without double-processing" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 20)
    create(:fare_rule, route: trip.route, bus_class: :ordinary, base_fare: 40_000)
    idempotency_key = "idem-replay-1"

    first = checkout(trip: trip, trip_seat_ids: nil, passengers: [ { full_name: "Grace" } ], idempotency_key: idempotency_key)
    second = checkout(trip: trip, trip_seat_ids: nil, passengers: [ { full_name: "Grace" } ], idempotency_key: idempotency_key)

    assert first.success?
    assert second.success?
    assert_equal first.booking.id, second.booking.id
    assert_equal 1, Booking.where(idempotency_key: idempotency_key).count
    assert_equal 19, trip.reload.seats_available # only decremented once
  end

  test "rolls back every write when a later step fails" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    available_seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))
    already_booked = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :booked)

    assert_no_difference [ "Booking.count", "Payment.count", "Passenger.count" ] do
      assert_raises(Interactor::Failure) do
        ActiveRecord::Base.transaction do
          Bookings::Checkout.call!(
            trip: trip,
            trip_seat_ids: [ available_seat.id, already_booked.id ],
            passengers: [ { full_name: "Grace" }, { full_name: "Bea" } ],
            contact_number: "09171234567",
            idempotency_key: SecureRandom.hex(8)
          )
        end
      end
    end

    assert available_seat.reload.available?
    assert already_booked.reload.booked?
  end

  test "fails via context.fail! (not an unhandled exception) on an already-booked seat" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    booked = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :booked)

    result = checkout(trip: trip, trip_seat_ids: [ booked.id ], passengers: [ { full_name: "Grace" } ])

    assert result.failure?
  end

  test "fails via context.fail! on insufficient ordinary capacity" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 0)
    create(:fare_rule, route: trip.route, bus_class: :ordinary, base_fare: 40_000)

    result = checkout(trip: trip, trip_seat_ids: nil, passengers: [ { full_name: "Grace" } ])

    assert result.failure?
    assert_equal "Not enough seats available", result.message
  end

  test "Form to Organizer handoff: a validated CheckoutForm's attributes work directly" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))

    form = CheckoutForm.new(
      trip_id: trip.id,
      trip_seat_ids: [ seat.id ],
      passengers: [ { full_name: "Grace" } ],
      contact_number: "09171234567",
      idempotency_key: SecureRandom.hex(8)
    )
    assert form.valid?, form.errors.full_messages.to_sentence

    result = nil
    ActiveRecord::Base.transaction do
      result = Bookings::Checkout.call!(
        trip: form.trip,
        trip_seat_ids: form.trip_seat_ids,
        passengers: form.passengers,
        contact_number: form.contact_number,
        idempotency_key: form.idempotency_key
      )
    end

    assert result.success?
    assert result.booking.persisted?
  end

  private

  def checkout(trip:, trip_seat_ids:, passengers:, contact_number: "09171234567", idempotency_key: SecureRandom.hex(8))
    Bookings::Checkout.call(
      trip: trip,
      trip_seat_ids: trip_seat_ids,
      passengers: passengers,
      contact_number: contact_number,
      idempotency_key: idempotency_key
    )
  end
end
