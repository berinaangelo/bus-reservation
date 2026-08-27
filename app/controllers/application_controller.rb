class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Pagy::Method

  # Bookings::Checkout.call! (and any future organizer-backed endpoint) raises this on a business
  # rule failure -- see kos/decisions/rails-thin-controllers-organizer-interactor-pattern.md.
  # Handled here so individual actions can stay a straight-line happy path.
  rescue_from Interactor::Failure do |exception|
    render json: { error: exception.context.message }, status: :unprocessable_entity
  end

  # Date::Error < ArgumentError, so this also covers TripSearch's Date.parse coercion on a
  # malformed `date` param.
  rescue_from ArgumentError do
    render json: { error: "Invalid request" }, status: :bad_request
  end

  # Raised by `authorize` (Pundit::Authorization) when the acting OperatorStaff isn't scoped to
  # the record's operator -- see kos/decisions/rails-pundit-for-authorization.md.
  rescue_from Pundit::NotAuthorizedError do
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
