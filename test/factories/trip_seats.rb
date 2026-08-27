FactoryBot.define do
  factory :trip_seat do
    trip
    seat
    status { :available }
    held_until { nil }
    booking { nil }
  end
end
