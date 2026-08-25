---
title: rails-skinny-models-behavior-in-interactors
tags: [bus-reservation, rails, backend, architecture]
date: 2026-08-25
---

ActiveRecord models stay skinny — persistence, associations, validations, and simple derived
attributes only. Business logic/behavior lives in Interactors (see
[[rails-thin-controllers-organizer-interactor-pattern]]) or other POROs, not in the model.

**Why:** the same discipline that keeps controllers thin has to apply to models too, or business
logic just piles back in there instead ("fat model" replacing "fat controller").

**How to apply:** if a model method does more than read/derive its own attributes or a simple
scope, it's a candidate to move into an Interactor, a
[[rails-query-objects-for-reused-queries|Query Object]], a
[[rails-form-objects-for-multi-model-forms|Form Object]], or a
[[rails-presenters-decorators-for-json-formatting|Presenter]] instead.
