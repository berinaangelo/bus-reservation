---
title: rails-pundit-for-authorization
tags: [bus-reservation, rails, backend, security]
date: 2026-08-25
---

Authorization goes through Pundit policy classes — one per resource — instead of scattered
`if current_user.operator_staff?` checks spread across controllers.

**Why:** the operator data boundary is a core guardrail (see [[mvp-scope]] and the original
entity-model discussion — OperatorStaff must never read/write another operator's
Trips/Routes/FareRules). A Pundit policy is the one place that scoping logic should live, checked
server-side, not trusted from the client.

```ruby
class TripPolicy < ApplicationPolicy
  def update?
    user.operator_staff? && record.route.operator_id == user.operator_id
  end
end
```

**How to apply:** any "can this user see/do this" check goes in the resource's policy class,
checked via `authorize`/`policy_scope` in the controller — not inlined as a conditional in a
controller action. Guest rider actions (booking lookup via reference_code + contact number) stay
outside Pundit's scope — that's a lookup match, not a role-based permission.
