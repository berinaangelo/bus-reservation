require "test_helper"

class CheckoutFormTest < ActiveSupport::TestCase
  setup do
    @reservable_trip = create(:trip, bus_unit: create(:aircon_bus_unit))
    @seat_a = create(:trip_seat, trip: @reservable_trip, seat: create(:seat, bus_unit: @reservable_trip.bus_unit))
    @seat_b = create(:trip_seat, trip: @reservable_trip, seat: create(:seat, bus_unit: @reservable_trip.bus_unit))
    @ordinary_trip = create(:trip, bus_unit: create(:ordinary_bus_unit))
  end

  test "valid for a reservable trip with matching seats and passengers" do
    form = build_form(
      trip_id: @reservable_trip.id,
      trip_seat_ids: [ @seat_a.id, @seat_b.id ],
      passengers: [ { full_name: "Grace Lim" }, { full_name: "Bea Santos" } ]
    )

    assert form.valid?, form.errors.full_messages.to_sentence
  end

  test "valid for an ordinary trip with a passenger count and no seat ids" do
    form = build_form(trip_id: @ordinary_trip.id, trip_seat_ids: nil, passengers: [ { full_name: "Grace Lim" } ])

    assert form.valid?, form.errors.full_messages.to_sentence
  end

  test "invalid without a trip_id" do
    form = build_form(trip_id: nil, trip_seat_ids: [ @seat_a.id ], passengers: [ { full_name: "Grace Lim" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_id], "can't be blank"
  end

  test "invalid when trip_id references nothing" do
    form = build_form(trip_id: -1, trip_seat_ids: [ @seat_a.id ], passengers: [ { full_name: "Grace Lim" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_id], "must exist"
  end

  test "invalid when the trip is not scheduled" do
    @reservable_trip.update!(status: :cancelled)
    form = build_form(trip_id: @reservable_trip.id, trip_seat_ids: [ @seat_a.id ], passengers: [ { full_name: "Grace Lim" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_id], "is not open for booking"
  end

  test "invalid when a reservable trip has no trip_seat_ids" do
    form = build_form(trip_id: @reservable_trip.id, trip_seat_ids: nil, passengers: [ { full_name: "Grace Lim" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_seat_ids], "must be provided for a reservable trip"
  end

  test "invalid when seat count doesn't match passenger count" do
    form = build_form(trip_id: @reservable_trip.id, trip_seat_ids: [ @seat_a.id ], passengers: [ { full_name: "Grace Lim" }, { full_name: "Bea Santos" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_seat_ids], "must match the number of passengers"
  end

  test "invalid when a seat is repeated" do
    form = build_form(trip_id: @reservable_trip.id, trip_seat_ids: [ @seat_a.id, @seat_a.id ], passengers: [ { full_name: "Grace Lim" }, { full_name: "Bea Santos" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_seat_ids], "must not repeat a seat"
  end

  test "invalid when an ordinary trip is given trip_seat_ids" do
    ordinary_seat = create(:trip_seat, trip: @ordinary_trip, seat: create(:seat, bus_unit: @ordinary_trip.bus_unit))
    form = build_form(trip_id: @ordinary_trip.id, trip_seat_ids: [ ordinary_seat.id ], passengers: [ { full_name: "Grace Lim" } ])

    assert_not form.valid?
    assert_includes form.errors[:trip_seat_ids], "must be blank for an ordinary-class trip"
  end

  test "invalid when a passenger has no full_name" do
    form = build_form(trip_id: @reservable_trip.id, trip_seat_ids: [ @seat_a.id ], passengers: [ { full_name: "" } ])

    assert_not form.valid?
    assert_includes form.errors[:passengers], "must each have a full_name"
  end

  test "invalid with no passengers" do
    form = build_form(trip_id: @reservable_trip.id, trip_seat_ids: [], passengers: [])

    assert_not form.valid?
    assert_includes form.errors[:passengers], "can't be blank"
  end

  test "invalid without contact_number or idempotency_key" do
    form = build_form(trip_id: @ordinary_trip.id, trip_seat_ids: nil, passengers: [ { full_name: "Grace Lim" } ], contact_number: nil, idempotency_key: nil)

    assert_not form.valid?
    assert_includes form.errors[:contact_number], "can't be blank"
    assert_includes form.errors[:idempotency_key], "can't be blank"
  end

  test "passengers= normalizes string-keyed hashes" do
    form = CheckoutForm.new(passengers: [ { "full_name" => "Grace Lim" } ])

    assert_equal "Grace Lim", form.passengers.first[:full_name]
  end

  test "contact_number= strips non-digit formatting" do
    form = CheckoutForm.new(contact_number: "0917 123 4567")

    assert_equal "09171234567", form.contact_number
  end

  private

  def build_form(trip_id:, trip_seat_ids:, passengers:, contact_number: "09171234567", idempotency_key: "idem-key-1")
    CheckoutForm.new(
      trip_id: trip_id,
      trip_seat_ids: trip_seat_ids,
      passengers: passengers,
      contact_number: contact_number,
      idempotency_key: idempotency_key
    )
  end
end
