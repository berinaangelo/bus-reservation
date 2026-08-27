FactoryBot.define do
  factory :payment do
    booking
    amount { 95_000 } # centavos
    status { :pending_cash }
    collected_at { nil }
  end
end
