FactoryBot.define do
  factory :operator do
    name { Faker::Company.unique.name }
    sequence(:franchise_number) { |n| "LTFRB-#{n}" }
    contact_info { Faker::PhoneNumber.cell_phone }
    active { true }
  end
end
