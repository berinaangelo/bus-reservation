FactoryBot.define do
  factory :ordinary_bus_unit do
    operator
    sequence(:plate_number) { |n| "ORD-#{1000 + n}" }
    total_seats { 50 }
    seat_layout { nil }
    active { true }
  end

  factory :aircon_bus_unit do
    operator
    sequence(:plate_number) { |n| "AIR-#{1000 + n}" }
    total_seats { 45 }
    seat_layout { { rows: 12, columns: 4 } }
    active { true }
  end

  factory :deluxe_bus_unit do
    operator
    sequence(:plate_number) { |n| "DLX-#{1000 + n}" }
    total_seats { 32 }
    seat_layout { { rows: 8, columns: 4 } }
    active { true }
  end

  factory :double_deck_bus_unit do
    operator
    sequence(:plate_number) { |n| "DD-#{1000 + n}" }
    total_seats { 70 }
    seat_layout { { lower: { rows: 9, columns: 4 }, upper: { rows: 9, columns: 4 } } }
    active { true }
  end
end
