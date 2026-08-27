class PaymentPolicy < ApplicationPolicy
  def update?
    user.operator_staff? && record.booking.trip.route.operator_id == user.operator_id
  end
end
