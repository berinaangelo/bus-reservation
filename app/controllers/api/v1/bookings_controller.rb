module Api
  module V1
    class BookingsController < ApplicationController
      def create
        form = CheckoutForm.new(checkout_params)
        return render json: { errors: form.errors.as_json }, status: :unprocessable_entity unless form.valid?

        result = nil
        ActiveRecord::Base.transaction do
          result = Bookings::Checkout.call!(
            trip: form.trip,
            trip_seat_ids: form.trip_seat_ids,
            passengers: form.passengers,
            contact_number: form.contact_number,
            idempotency_key: form.idempotency_key
          )
        end

        render json: BookingPresenter.new(result.booking), status: :created
      end

      def show
        booking = find_booking
        return if booking.nil? # find_booking already rendered the error response

        render json: BookingPresenter.new(booking)
      end

      # Requires the same reference_code + contact_number verification as #show -- per
      # kos/decisions/ux/mockups/booking-detail-cancel.html, this isn't a second place to
      # re-enter that pair, but a direct/bookmarked request must still prove it before mutating
      # anything.
      def cancel
        booking = find_booking
        return if booking.nil?

        result = nil
        ActiveRecord::Base.transaction do
          result = Bookings::Cancel.call!(booking: booking)
        end

        render json: BookingPresenter.new(result.booking)
      end

      private

      def find_booking
        lookup = BookingLookup.new(reference_code: params[:reference_code], contact_number: params[:contact_number])
        if lookup.invalid_code?
          render json: { error: "Invalid reference code" }, status: :unprocessable_entity
          return nil
        end

        booking = lookup.call
        render json: { error: "Booking not found" }, status: :not_found if booking.nil?
        booking
      end

      def checkout_params
        params.permit(:trip_id, :contact_number, :idempotency_key, trip_seat_ids: [], passengers: [ :full_name ])
      end
    end
  end
end
