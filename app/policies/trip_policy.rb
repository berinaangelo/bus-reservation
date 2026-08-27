class TripPolicy < ApplicationPolicy
  def index?
    user.operator_staff?
  end

  def show?
    same_operator?
  end

  def create?
    same_operator?
  end

  def update?
    same_operator?
  end

  def destroy?
    same_operator?
  end

  # Distinct from update? (Trip CRUD editing) on purpose -- check-in and schedule-editing
  # are different permissions that may diverge later (e.g. junior staff allowed to check in but
  # not reschedule).
  def manage_manifest?
    same_operator?
  end

  private

  def same_operator?
    user.operator_staff? && record.route.operator_id == user.operator_id
  end
end
