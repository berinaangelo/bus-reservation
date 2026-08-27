# Validates and shapes a rider's checkout submission before it's handed to Bookings::Checkout.
# See kos/decisions/rails-form-objects-for-multi-model-forms.md -- Checkout is the canonical
# case for a Form Object here, since the fields don't map 1:1 onto one AR model.
#
# This form only checks what's knowable from the request + a live Trip lookup (including trip
# status, since that's cheap and gives fast feedback). It deliberately does NOT check seat
# availability or fare existence -- both can change between form validation and the actual
# checkout transaction, so that's Bookings::Checkout's job, re-checked under a real DB lock.
class CheckoutForm
  include ActiveModel::Model

  attr_accessor :trip_id, :idempotency_key, :trip_seat_ids
  attr_reader :passengers, :contact_number

  validates :trip_id, :contact_number, :idempotency_key, presence: true
  validates :passengers, presence: true
  validate :trip_exists
  validate :trip_is_scheduled
  validate :passengers_have_names
  validate :seat_selection_matches_bus_class

  def passengers=(value)
    @passengers = value&.map { |p| p.respond_to?(:with_indifferent_access) ? p.with_indifferent_access : p }
  end

  # Digits-only, so a rider entering "0917 123 4567" at checkout and "09171234567" at lookup (or
  # vice versa) still match -- see BookingLookup, which normalizes its own input the same way.
  def contact_number=(value)
    @contact_number = value&.gsub(/\D/, "")
  end

  def trip
    @trip ||= Trip.find_by(id: trip_id)
  end

  private

  def trip_exists
    errors.add(:trip_id, "must exist") if trip.nil?
  end

  def trip_is_scheduled
    return if trip.nil?

    errors.add(:trip_id, "is not open for booking") unless trip.scheduled?
  end

  def passengers_have_names
    return if passengers.blank?

    unless passengers.is_a?(Array) && passengers.all? { |p| p.is_a?(Hash) && p[:full_name].present? }
      errors.add(:passengers, "must each have a full_name")
    end
  end

  def seat_selection_matches_bus_class
    return if trip.nil? || passengers.blank?

    if trip.bus_unit.reservable?
      validate_reservable_seat_selection
    elsif trip_seat_ids.present?
      errors.add(:trip_seat_ids, "must be blank for an ordinary-class trip")
    end
  end

  def validate_reservable_seat_selection
    if trip_seat_ids.blank?
      errors.add(:trip_seat_ids, "must be provided for a reservable trip")
    elsif trip_seat_ids.uniq.size != trip_seat_ids.size
      errors.add(:trip_seat_ids, "must not repeat a seat")
    elsif trip_seat_ids.size != passengers.size
      errors.add(:trip_seat_ids, "must match the number of passengers")
    end
  end
end
