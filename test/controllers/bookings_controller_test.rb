require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  test "checkout on a reservable-class trip returns 201 with a valid reference_code" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))

    post api_v1_bookings_path, params: {
      trip_id: trip.id,
      trip_seat_ids: [ seat.id ],
      passengers: [ { full_name: "Grace Lim" } ],
      contact_number: "09171234567",
      idempotency_key: SecureRandom.hex(8)
    }

    assert_response :created
    body = JSON.parse(response.body)
    assert ReferenceCode.valid?(body["reference_code"].delete("-"))
  end

  test "broadcasts to the manifest channel on checkout" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit))

    assert_broadcast_on(ManifestChannel.broadcasting_for(trip), type: "booking_created") do
      post api_v1_bookings_path, params: {
        trip_id: trip.id,
        trip_seat_ids: [ seat.id ],
        passengers: [ { full_name: "Grace Lim" } ],
        contact_number: "09171234567",
        idempotency_key: SecureRandom.hex(8)
      }
    end
  end

  test "checkout on an ordinary-class trip returns 201" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 10)
    create(:fare_rule, route: trip.route, bus_class: :ordinary, base_fare: 40_000)

    post api_v1_bookings_path, params: {
      trip_id: trip.id,
      passengers: [ { full_name: "Grace Lim" } ],
      contact_number: "09171234567",
      idempotency_key: SecureRandom.hex(8)
    }

    assert_response :created
  end

  test "invalid form returns 422" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    post api_v1_bookings_path, params: {
      trip_id: trip.id,
      passengers: [ { full_name: "Grace Lim" } ],
      contact_number: "09171234567"
      # idempotency_key missing
    }

    assert_response :unprocessable_entity
  end

  test "an already-booked seat returns 422 with the organizer's message" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)
    seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :booked)

    post api_v1_bookings_path, params: {
      trip_id: trip.id,
      trip_seat_ids: [ seat.id ],
      passengers: [ { full_name: "Grace Lim" } ],
      contact_number: "09171234567",
      idempotency_key: SecureRandom.hex(8)
    }

    assert_response :unprocessable_entity
    assert_equal "Seat no longer available", JSON.parse(response.body)["error"]
  end

  test "resubmitting the same idempotency_key returns the same booking" do
    trip = create(:trip, bus_unit: create(:ordinary_bus_unit), seats_available: 10)
    create(:fare_rule, route: trip.route, bus_class: :ordinary, base_fare: 40_000)
    idempotency_key = SecureRandom.hex(8)
    params = { trip_id: trip.id, passengers: [ { full_name: "Grace Lim" } ], contact_number: "09171234567", idempotency_key: idempotency_key }

    post api_v1_bookings_path, params: params
    first_code = JSON.parse(response.body)["reference_code"]

    post api_v1_bookings_path, params: params
    second_code = JSON.parse(response.body)["reference_code"]

    assert_response :created
    assert_equal first_code, second_code
  end

  test "show finds a booking by reference_code and contact_number" do
    booking = create(:booking, contact_number: "09171234567")

    get api_v1_booking_path(reference_code: booking.reference_code), params: { contact_number: "0917 123 4567" }

    assert_response :success
    assert_equal ReferenceCode.format(booking.reference_code), JSON.parse(response.body)["reference_code"]
  end

  test "show returns 422 for a bad checksum" do
    get api_v1_booking_path(reference_code: "4XK7QM0"), params: { contact_number: "09171234567" }

    assert_response :unprocessable_entity
  end

  test "show returns 404 for a valid checksum with no matching booking" do
    get api_v1_booking_path(reference_code: ReferenceCode.generate), params: { contact_number: "09171234567" }

    assert_response :not_found
  end

  test "show returns 404 when the contact_number doesn't match" do
    booking = create(:booking, contact_number: "09171234567")

    get api_v1_booking_path(reference_code: booking.reference_code), params: { contact_number: "09990000000" }

    assert_response :not_found
  end

  test "cancel voids a confirmed booking and releases its seat" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    booking = create(:booking, trip: trip, contact_number: "09171234567")
    trip_seat = create(:trip_seat, trip: trip, seat: create(:seat, bus_unit: trip.bus_unit), status: :booked, booking: booking)
    create(:passenger, booking: booking, trip_seat: trip_seat)

    patch cancel_api_v1_booking_path(reference_code: booking.reference_code), params: { contact_number: "0917 123 4567" }

    assert_response :success
    assert_equal "cancelled", JSON.parse(response.body)["status"]
    assert trip_seat.reload.available?
  end

  test "cancel is idempotent against a double-tap" do
    booking = create(:booking, contact_number: "09171234567")

    patch cancel_api_v1_booking_path(reference_code: booking.reference_code), params: { contact_number: "09171234567" }
    patch cancel_api_v1_booking_path(reference_code: booking.reference_code), params: { contact_number: "09171234567" }

    assert_response :success
    assert_equal "cancelled", JSON.parse(response.body)["status"]
  end

  test "cancel returns 422 for a bad checksum" do
    patch cancel_api_v1_booking_path(reference_code: "4XK7QM0"), params: { contact_number: "09171234567" }

    assert_response :unprocessable_entity
  end

  test "cancel returns 404 when the contact_number doesn't match" do
    booking = create(:booking, contact_number: "09171234567")

    patch cancel_api_v1_booking_path(reference_code: booking.reference_code), params: { contact_number: "09990000000" }

    assert_response :not_found
  end
end
