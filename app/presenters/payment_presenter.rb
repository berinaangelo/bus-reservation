# JSON shape for a Payment, as shown on the trip manifest's Paid toggle. See
# kos/decisions/rails-presenters-decorators-for-json-formatting.md.
class PaymentPresenter < SimpleDelegator
  def as_json(*)
    {
      id: id,
      status: status,
      amount: amount,
      collected_at: collected_at&.in_time_zone("Asia/Manila")&.iso8601
    }
  end

  # SimpleDelegator forwards #to_json to the wrapped object via method_missing even when #as_json
  # is overridden here -- without this, `render json:` would silently render the raw Payment
  # instead of this presenter's shape.
  def to_json(*args)
    as_json.to_json(*args)
  end
end
