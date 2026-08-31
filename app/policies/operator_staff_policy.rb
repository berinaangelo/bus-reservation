# Flat authorization, matching every other operator-admin policy: any active staff member can
# manage staff at their own operator (no admin/role tier -- see
# kos/decisions/rails-pundit-for-authorization.md). Revisit if the product later needs a
# staff-vs-admin distinction.
class OperatorStaffPolicy < ApplicationPolicy
  def index?
    user.operator_staff?
  end

  def show?
    same_operator?
  end

  def create?
    user.operator_staff?
  end

  def update?
    same_operator?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(operator: user.operator)
    end
  end

  private

  def same_operator?
    user.operator_staff? && record.operator_id == user.operator_id
  end
end
