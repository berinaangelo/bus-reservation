require "test_helper"

class TripPresenterTest < ActiveSupport::TestCase
  test "includes route, operator, class, fare, and seats_available" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit), departure_at: Time.utc(2026, 9, 1, 1, 0), arrival_at: Time.utc(2026, 9, 1, 6, 0))
    create(:fare_rule, route: trip.route, bus_class: :aircon, base_fare: 95_000)

    json = TripPresenter.new(trip, seats_available: 12).as_json

    assert_equal trip.id, json[:id]
    assert_equal "scheduled", json[:status]
    assert_equal :aircon, json[:bus_class]
    assert_equal trip.route.operator.name, json[:operator]
    assert_equal trip.route.origin_terminal.name, json[:origin_terminal]
    assert_equal trip.route.destination_terminal.name, json[:destination_terminal]
    assert_equal 95_000, json[:fare]
    assert_equal "2026-09-01T09:00:00+08:00", json[:departure_at]
    assert_equal 12, json[:seats_available]
  end

  test "fare is nil when no fare rule is configured" do
    trip = create(:trip, bus_unit: create(:aircon_bus_unit))

    json = TripPresenter.new(trip, seats_available: 0).as_json

    assert_nil json[:fare]
  end
end
