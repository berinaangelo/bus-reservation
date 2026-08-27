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
    assert_equal 1, body.size
    assert_equal @trip.id, body.first["id"]
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
end
