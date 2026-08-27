FactoryBot.define do
  factory :terminal do
    sequence(:name) { |n| "#{Faker::Address.city} Terminal #{n}" }
    city { Faker::Address.city }
    province { Faker::Address.state }
    address { Faker::Address.street_address }
  end
end
