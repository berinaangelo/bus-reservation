class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  def self.seat_hold_ttl_minutes
    find_by(key: "seat_hold_ttl_minutes")&.value&.to_i || 60
  end

  def self.operator_session_ttl_minutes
    find_by(key: "operator_session_ttl_minutes")&.value&.to_i || 1440
  end
end
