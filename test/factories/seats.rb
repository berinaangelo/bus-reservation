FactoryBot.define do
  factory :seat do
    association :bus_unit, factory: :aircon_bus_unit
    sequence(:seat_number) { |n| "#{('A'..'Z').to_a[n % 26]}#{(n / 26) + 1}" }
    seat_type { :window }
    deck { nil }
  end
end
