FactoryBot.define do
  factory :passenger do
    booking
    trip_seat { nil }
    full_name { Faker::Name.name }
  end
end
