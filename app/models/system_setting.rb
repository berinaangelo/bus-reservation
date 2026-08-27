class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true

  def self.seat_hold_ttl_minutes
    find_by(key: "seat_hold_ttl_minutes")&.value&.to_i || 60
  end
end
