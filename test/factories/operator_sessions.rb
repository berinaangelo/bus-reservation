# For model-level tests where only DB state matters (uniqueness, expiry scoping). Request tests
# that need a real bearer token to send should call OperatorSession.issue_for(create(:operator_staff))
# directly instead -- the raw token isn't derivable from a stored digest.
FactoryBot.define do
  factory :operator_session do
    operator_staff
    token_digest { OperatorSession.digest(SecureRandom.hex(32)) }
    expires_at { 1.day.from_now }
  end
end
