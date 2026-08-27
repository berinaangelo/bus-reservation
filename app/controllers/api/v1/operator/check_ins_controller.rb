module Api
  module V1
    module Operator
      class CheckInsController < BaseController
        def create
          trip = Trip.find_by(id: params[:trip_id])
          return render json: { error: "Trip not found" }, status: :not_found if trip.nil?
          authorize trip, :manage_manifest?

          booking = find_booking(trip)
          return if booking.nil?

          result = nil
          ActiveRecord::Base.transaction { result = Bookings::CheckIn.call!(booking: booking) }

          render json: { rows: result.booking.passengers.map { |p| ManifestRowPresenter.new(p) } }
        end

        private

        # Mirrors Api::V1::BookingsController#find_booking's invalid-checksum-vs-not-found
        # distinction, adapted to trip-scoping instead of contact_number-scoping -- a code valid
        # for a different trip correctly 404s here, never leaking across trips.
        def find_booking(trip)
          code = params[:reference_code].to_s.delete("-").upcase
          unless ReferenceCode.valid?(code)
            render json: { error: "Invalid reference code" }, status: :unprocessable_entity
            return nil
          end

          booking = trip.bookings.includes(passengers: { trip_seat: :seat }, payment: {}).find_by(reference_code: code)
          render json: { error: "Booking not found" }, status: :not_found if booking.nil?
          booking
        end
      end
    end
  end
end
