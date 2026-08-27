FactoryBot.define do
  factory :booking do
    trip
    reference_code { ReferenceCode.generate }
    status { :confirmed }
    total_amount { 95_000 } # centavos
    contact_number { Faker::PhoneNumber.cell_phone }
    seat_count { nil }
    sequence(:idempotency_key) { |n| "idem-key-#{n}-#{SecureRandom.hex(4)}" }

    trait :checked_in do
      checked_in_at { Time.current }
    end
  end
end
