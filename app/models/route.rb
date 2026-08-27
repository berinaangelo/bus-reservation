class Route < ApplicationRecord
  belongs_to :operator
  belongs_to :origin_terminal, class_name: "Terminal", inverse_of: :routes_as_origin
  belongs_to :destination_terminal, class_name: "Terminal", inverse_of: :routes_as_destination
  has_many :trips, dependent: :restrict_with_error
  has_many :fare_rules, dependent: :destroy

  validates :operator_id, uniqueness: { scope: [ :origin_terminal_id, :destination_terminal_id ] }
  validate :terminals_differ

  private

  def terminals_differ
    return if origin_terminal_id.blank? || destination_terminal_id.blank?

    errors.add(:destination_terminal_id, "must differ from origin terminal") if origin_terminal_id == destination_terminal_id
  end
end
