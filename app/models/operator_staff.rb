class OperatorStaff < ApplicationRecord
  self.table_name = "operator_staff"

  has_secure_password

  belongs_to :operator
  has_many :operator_sessions, dependent: :destroy
  has_many :password_reset_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  # Assumed by the example Pundit policy in kos/decisions/rails-pundit-for-authorization.md
  # (`user.operator_staff?`) -- OperatorStaff is the only Pundit user type in this app.
  def operator_staff?
    true
  end

  LOCKOUT_THRESHOLD = 5
  LOCKOUT_DURATION = 15.minutes
  LOCKOUT_MESSAGE = "Account temporarily locked after repeated failed attempts. Try again in 15 minutes."

  def locked?
    locked_at.present? && locked_at > LOCKOUT_DURATION.ago
  end

  # Called after a failed authenticate(). Auto-clears a stale (expired) lock before counting this
  # attempt, so the first attempt after a lock expires doesn't immediately re-lock. Only sets
  # locked_at on the crossing attempt (threshold - 1 -> threshold), so it never extends an
  # already-active lock window on repeated post-lock attempts.
  def register_failed_attempt!
    if locked_at.present? && !locked?
      update!(failed_attempts: 1, locked_at: nil)
      return
    end

    new_count = failed_attempts + 1
    attrs = { failed_attempts: new_count }
    attrs[:locked_at] = Time.current if new_count >= LOCKOUT_THRESHOLD && locked_at.nil?
    update!(**attrs)
  end

  def reset_lockout!
    update!(failed_attempts: 0, locked_at: nil) if failed_attempts.positive? || locked_at.present?
  end
end
