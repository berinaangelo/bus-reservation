require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @route = create(:route)
    @trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit), departure_at: 1.day.from_now, arrival_at: 1.day.from_now + 5.hours)
  end

  test "returns matching trips" do
    get api_v1_trips_path, params: {
      origin_terminal_id: @route.origin_terminal_id,
      destination_terminal_id: @route.destination_terminal_id,
      date: @trip.departure_at.in_time_zone("Asia/Manila").to_date.to_s
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["trips"].size
    assert_equal @trip.id, body["trips"].first["id"]
    assert_nil body["meta"]["next_cursor"]
    assert_equal false, body["meta"]["has_more"]
  end

  test "includes seats_available per trip" do
    get api_v1_trips_path, params: {
      origin_terminal_id: @route.origin_terminal_id,
      destination_terminal_id: @route.destination_terminal_id,
      date: @trip.departure_at.in_time_zone("Asia/Manila").to_date.to_s
    }

    body = JSON.parse(response.body)
    assert body["trips"].first.key?("seats_available")
  end

  test "paginates with a cursor once results exceed the page size" do
    date = @trip.departure_at.in_time_zone("Asia/Manila").to_date
    20.times do |n|
      create(:trip, route: @route, bus_unit: create(:aircon_bus_unit),
        departure_at: date.in_time_zone("Asia/Manila").beginning_of_day + (n + 1).hours,
        arrival_at: date.in_time_zone("Asia/Manila").beginning_of_day + (n + 1).hours + 3.hours)
    end

    get api_v1_trips_path, params: {
      origin_terminal_id: @route.origin_terminal_id,
      destination_terminal_id: @route.destination_terminal_id,
      date: date.to_s
    }

    body = JSON.parse(response.body)
    assert_equal 20, body["trips"].size
    assert body["meta"]["has_more"]
    assert body["meta"]["next_cursor"].present?

    get api_v1_trips_path, params: {
      origin_terminal_id: @route.origin_terminal_id,
      destination_terminal_id: @route.destination_terminal_id,
      date: date.to_s,
      cursor: body["meta"]["next_cursor"]
    }

    next_body = JSON.parse(response.body)
    assert_equal 1, next_body["trips"].size
    assert_equal false, next_body["meta"]["has_more"]
    assert_nil next_body["meta"]["next_cursor"]
  end

  test "returns 400 when a required param is missing" do
    get api_v1_trips_path, params: { origin_terminal_id: @route.origin_terminal_id }

    assert_response :bad_request
  end

  test "returns 400 for an unparseable date" do
    get api_v1_trips_path, params: {
      origin_terminal_id: @route.origin_terminal_id,
      destination_terminal_id: @route.destination_terminal_id,
      date: "not-a-date"
    }

    assert_response :bad_request
  end

  test "#seats returns the seat map for a reservable trip, naturally sorted" do
    bus_unit = create(:aircon_bus_unit)
    reservable_trip = create(:trip, bus_unit: bus_unit)
    seat_9 = create(:seat, bus_unit: bus_unit, seat_number: "9A")
    seat_10 = create(:seat, bus_unit: bus_unit, seat_number: "10A")
    create(:trip_seat, trip: reservable_trip, seat: seat_10, status: :available)
    create(:trip_seat, trip: reservable_trip, seat: seat_9, status: :booked)

    get seats_api_v1_trip_path(reservable_trip)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal %w[9A 10A], body["trip_seats"].map { |ts| ts["seat_number"] }
    assert_equal "booked", body["trip_seats"].first["status"]
    assert_equal "available", body["trip_seats"].second["status"]
    assert_equal({ "rows" => 12, "columns" => 4 }, body["seat_layout"])
  end

  test "#seats returns an empty seat map for an ordinary trip" do
    ordinary_trip = create(:trip, bus_unit: create(:ordinary_bus_unit))

    get seats_api_v1_trip_path(ordinary_trip)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body["trip_seats"]
    assert_nil body["seat_layout"]
  end

  test "#seats returns 404 for an unknown trip" do
    get seats_api_v1_trip_path(id: -1)

    assert_response :not_found
  end
end
