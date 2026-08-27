# A bearer-token session for OperatorStaff login. Only the SHA-256 digest of the token is ever
# persisted -- the raw token exists solely in the issue_for return value and the client's
# Authorization header, exactly as OperatorStaff never persists a raw password.
#
# SHA-256, not bcrypt: bcrypt is deliberately slow and salted so it can't be looked up by value --
# fine for a password, since you already know which OperatorStaff row to check against. A bearer
# token has no such secondary identifier; the raw token itself is what the client presents, so
# authenticate needs `WHERE token_digest = ?` directly. That requires a deterministic hash. Since
# the token is 256 bits of SecureRandom, not a human-chosen secret, a fast deterministic hash is
# both correct and safe here.
class OperatorSession < ApplicationRecord
  belongs_to :operator_staff

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  TOKEN_BYTES = 32

  # Returns [session, raw_token].
  def self.issue_for(operator_staff)
    raw_token = SecureRandom.hex(TOKEN_BYTES)
    session = create!(
      operator_staff: operator_staff,
      token_digest: digest(raw_token),
      expires_at: SystemSetting.operator_session_ttl_minutes.minutes.from_now
    )
    [ session, raw_token ]
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def expired?
    expires_at <= Time.current
  end
end
