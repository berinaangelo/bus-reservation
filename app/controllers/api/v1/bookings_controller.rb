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
        lookup = BookingLookup.new(reference_code: params[:reference_code], contact_number: params[:contact_number])
        return render json: { error: "Invalid reference code" }, status: :unprocessable_entity if lookup.invalid_code?

        booking = lookup.call
        return render json: { error: "Booking not found" }, status: :not_found if booking.nil?

        render json: BookingPresenter.new(booking)
      end

      private

      def checkout_params
        params.permit(:trip_id, :contact_number, :idempotency_key, trip_seat_ids: [], passengers: [ :full_name ])
      end
    end
  end
end
