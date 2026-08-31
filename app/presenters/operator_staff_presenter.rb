# JSON shape for an OperatorStaff on the operator-admin console. Never includes password_digest or
# any token/lockout internals beyond the two fields the UI needs to show status.
class OperatorStaffPresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      operator_id: operator_id,
      name: name,
      email: email,
      active: active,
      locked: locked?
    }
  end

  def to_json(*args)
    as_json.to_json(*args)
  end
end
