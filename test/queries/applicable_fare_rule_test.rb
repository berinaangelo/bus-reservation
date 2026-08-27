require "test_helper"

class ApplicableFareRuleTest < ActiveSupport::TestCase
  setup do
    @route = create(:route)
  end

  test "resolves the fare rule for the trip's route and bus_class" do
    aircon_rule = create(:fare_rule, route: @route, bus_class: :aircon, base_fare: 95_000)
    create(:fare_rule, route: @route, bus_class: :deluxe, base_fare: 150_000)
    trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit))

    assert_equal aircon_rule, resolve(trip)
  end

  test "picks the latest effective_date among several candidates" do
    older = create(:fare_rule, route: @route, bus_class: :aircon, effective_date: 10.days.ago.to_date)
    newer = create(:fare_rule, route: @route, bus_class: :aircon, effective_date: 1.day.ago.to_date)
    trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit))

    assert_equal newer, resolve(trip)
    assert_not_equal older, resolve(trip)
  end

  test "ignores a future-dated rule" do
    create(:fare_rule, route: @route, bus_class: :aircon, effective_date: 1.day.from_now.to_date)
    trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit), departure_at: 12.hours.from_now)

    assert_nil resolve(trip)
  end

  test "returns nil when no fare rule applies" do
    trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit))

    assert_nil resolve(trip)
  end

  test "breaks a tie on identical effective_date by the higher id" do
    same_date = Date.current
    first = create(:fare_rule, route: @route, bus_class: :aircon, effective_date: same_date, base_fare: 90_000)
    second = create(:fare_rule, route: @route, bus_class: :aircon, effective_date: same_date, base_fare: 91_000)
    trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit))

    assert_equal second, resolve(trip)
    assert second.id > first.id
  end

  test "buckets the trip by its Manila calendar day, not its UTC calendar day" do
    # 8:30 PM UTC on Aug 31 is 4:30 AM Manila on Sep 1.
    create(:fare_rule, route: @route, bus_class: :aircon, effective_date: Date.new(2026, 9, 1))
    trip = create(:trip, route: @route, bus_unit: create(:aircon_bus_unit), departure_at: Time.utc(2026, 8, 31, 20, 30), arrival_at: Time.utc(2026, 8, 31, 23, 30))

    assert resolve(trip).present?
  end

  private

  def resolve(trip)
    ApplicableFareRule.new(trip: trip).call
  end
end
