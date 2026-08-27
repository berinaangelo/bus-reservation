FactoryBot.define do
  factory :operator_staff do
    operator
    sequence(:email) { |n| "staff#{n}@#{Faker::Internet.domain_name}" }
    password { "password123" }
    name { Faker::Name.name }
    active { true }
  end
end
