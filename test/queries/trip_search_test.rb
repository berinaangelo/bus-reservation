require "test_helper"

class TripSearchTest < ActiveSupport::TestCase
  setup do
    @origin = create(:terminal)
    @destination = create(:terminal)
    @route = create(:route, origin_terminal: @origin, destination_terminal: @destination)
  end

  test "finds a scheduled trip on the searched route and date" do
    trip = make_trip(departure_at: manila_time(2026, 9, 1, 8, 0))

    assert_equal [ trip ], search(date: Date.new(2026, 9, 1)).call
  end

  test "excludes trips on a different route" do
    other_route = create(:route)
    make_trip(route: other_route, departure_at: manila_time(2026, 9, 1, 8, 0))

    assert_empty search(date: Date.new(2026, 9, 1)).call
  end

  test "excludes trips that aren't scheduled" do
    make_trip(departure_at: manila_time(2026, 9, 1, 8, 0), status: :cancelled)

    assert_empty search(date: Date.new(2026, 9, 1)).call
  end

  test "excludes trips outside the searched date" do
    make_trip(departure_at: manila_time(2026, 9, 2, 0, 30))

    assert_empty search(date: Date.new(2026, 9, 1)).call
  end

  test "includes a trip departing right after Manila midnight even though it's still the prior UTC day" do
    # 12:30 AM Manila on Sep 1 is 4:30 PM UTC on Aug 31.
    trip = make_trip(departure_at: manila_time(2026, 9, 1, 0, 30))

    assert_equal [ trip ], search(date: Date.new(2026, 9, 1)).call
  end

  test "a trip is bucketed by its Manila calendar day, not its UTC calendar day" do
    # 8:30 PM UTC on Aug 31 is 4:30 AM Manila on Sep 1.
    trip = make_trip(departure_at: Time.utc(2026, 8, 31, 20, 30), arrival_at: Time.utc(2026, 8, 31, 23, 30))

    assert_empty search(date: Date.new(2026, 8, 31)).call
    assert_equal [ trip ], search(date: Date.new(2026, 9, 1)).call
  end

  test "accepts a string date" do
    trip = make_trip(departure_at: manila_time(2026, 9, 1, 8, 0))

    assert_equal [ trip ], search(date: "2026-09-01").call
  end

  test "orders results by departure time" do
    later = make_trip(departure_at: manila_time(2026, 9, 1, 18, 0))
    earlier = make_trip(departure_at: manila_time(2026, 9, 1, 6, 0))

    assert_equal [ earlier, later ], search(date: Date.new(2026, 9, 1)).call
  end

  test "preloads bus_unit and route associations to avoid N+1" do
    make_trip(departure_at: manila_time(2026, 9, 1, 8, 0))

    trip = search(date: Date.new(2026, 9, 1)).call.first

    assert trip.association(:bus_unit).loaded?
    assert trip.association(:route).loaded?
    assert trip.route.association(:operator).loaded?
    assert trip.route.association(:origin_terminal).loaded?
    assert trip.route.association(:destination_terminal).loaded?
  end

  private

  def search(date:)
    TripSearch.new(origin_terminal_id: @origin.id, destination_terminal_id: @destination.id, date: date)
  end

  def make_trip(route: @route, departure_at:, arrival_at: departure_at + 3.hours, status: :scheduled)
    create(:trip, route: route, departure_at: departure_at, arrival_at: arrival_at, status: status)
  end

  def manila_time(year, month, day, hour, minute)
    ActiveSupport::TimeZone["Asia/Manila"].local(year, month, day, hour, minute).utc
  end
end
