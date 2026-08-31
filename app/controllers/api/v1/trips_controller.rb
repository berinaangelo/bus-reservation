module Api
  module V1
    class TripsController < ApplicationController
      def index
        missing = %i[origin_terminal_id destination_terminal_id date].select { |key| params[key].blank? }
        return render json: { error: "Missing required params: #{missing.join(', ')}" }, status: :bad_request if missing.any?

        trips_relation = TripSearch.new(
          origin_terminal_id: params[:origin_terminal_id],
          destination_terminal_id: params[:destination_terminal_id],
          date: params[:date]
        ).call

        # Cursor (keyset), not page-based -- trip search is a volatile list (seats/trips can
        # change between page loads) and riders only ever page forward, never jump to a page
        # number. See kos/decisions/rails-pagination-and-batch-export-processing.md.
        pagy, trips = pagy(:keyset, trips_relation, page_key: "cursor")
        seats_by_trip_id = TripSeatAvailability.new(trips).call

        render json: {
          trips: trips.map { |trip| TripPresenter.new(trip, seats_available: seats_by_trip_id[trip.id]) },
          meta: { next_cursor: pagy.next, has_more: !pagy.next.nil? }
        }
      end

      # The seat map for a reservable-class trip (aircon/deluxe/double-deck) -- Seat Selection
      # fetches this to render the grid. Ordinary-class trips have no TripSeat rows, so this
      # renders an empty list for them rather than erroring; the frontend doesn't call this
      # endpoint for ordinary trips at all (it already has seats_available from search), but a
      # stray/direct call should still get a sane response instead of a 500.
      def seats
        trip = Trip.find_by(id: params[:id])
        return render json: { error: "Trip not found" }, status: :not_found if trip.nil?

        trip_seats = trip.trip_seats.includes(:seat).references(:seat)
          .order(Arel.sql("LENGTH(seats.seat_number), seats.seat_number"))

        render json: {
          trip_seats: trip_seats.map { |trip_seat| TripSeatPresenter.new(trip_seat) },
          seat_layout: trip.bus_unit.seat_layout
        }
      end
    end
  end
end
