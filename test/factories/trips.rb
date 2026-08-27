FactoryBot.define do
  factory :trip do
    route
    association :bus_unit, factory: :aircon_bus_unit
    departure_at { 1.day.from_now }
    arrival_at { 1.day.from_now + 5.hours }
    status { :scheduled }
    seats_available { nil }
    lock_version { 0 }
  end
end
