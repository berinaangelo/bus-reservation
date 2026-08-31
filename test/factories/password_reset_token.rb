FactoryBot.define do
  factory :password_reset_token do
    operator_staff
    sequence(:token_digest) { |n| "digest#{n}" }
    expires_at { 30.minutes.from_now }
  end
end
