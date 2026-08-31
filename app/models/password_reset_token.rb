# A single-use, short-lived token for resetting an OperatorStaff's password. Mirrors
# OperatorSession's bearer-token pattern exactly: only the SHA-256 digest of the token is ever
# persisted, the raw token exists solely in the issue_for return value and the mailed link.
class PasswordResetToken < ApplicationRecord
  belongs_to :operator_staff

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  TOKEN_BYTES = 32
  TTL = 30.minutes

  # Returns [token, raw_token]. Invalidates any prior outstanding tokens for this staff first --
  # only the most recently requested reset link should ever work.
  def self.issue_for(operator_staff)
    where(operator_staff: operator_staff).destroy_all
    raw_token = SecureRandom.hex(TOKEN_BYTES)
    token = create!(
      operator_staff: operator_staff,
      token_digest: digest(raw_token),
      expires_at: TTL.from_now
    )
    [ token, raw_token ]
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
