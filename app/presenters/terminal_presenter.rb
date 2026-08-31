# JSON shape for a terminal in the Trip Search autocomplete. See
# kos/decisions/rails-presenters-decorators-for-json-formatting.md.
class TerminalPresenter < SimpleDelegator
  def as_json(*)
    { id: id, name: name, city: city }
  end

  # SimpleDelegator forwards #to_json to the wrapped object via method_missing even when #as_json
  # is overridden here -- without this, `render json:` would silently render the raw Terminal
  # instead of this presenter's shape.
  def to_json(*args)
    as_json.to_json(*args)
  end
end
