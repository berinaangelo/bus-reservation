FactoryBot.define do
  factory :route do
    operator
    origin_terminal { association :terminal }
    destination_terminal { association :terminal }
    distance_km { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    estimated_duration_minutes { Faker::Number.between(from: 60, to: 600) }
  end
end
