class RoutePolicy < ApplicationPolicy
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

  private

  def same_operator?
    user.operator_staff? && record.operator_id == user.operator_id
  end
end
