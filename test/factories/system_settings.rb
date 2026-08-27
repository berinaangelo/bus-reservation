FactoryBot.define do
  factory :system_setting do
    sequence(:key) { |n| "setting_key_#{n}" }
    value { "60" }
  end
end
