FactoryBot.define do
  factory :payment do
    booking
    amount { 95_000 } # centavos
    status { :pending_cash }
    collected_at { nil }

    trait :collected do
      status { :collected }
      collected_at { Time.current }
    end
  end
end
