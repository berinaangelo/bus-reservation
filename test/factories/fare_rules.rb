FactoryBot.define do
  factory :fare_rule do
    route
    bus_class { :aircon }
    base_fare { 95_000 } # centavos
    effective_date { Date.current }
  end
end
