module Api
  module V1
    module Operator
      class TripsController < BaseController
        before_action :set_trip, only: [ :show, :update, :destroy ]

        def index
          authorize Trip
          scope = Trip.joins(:route).where(routes: { operator_id: current_operator_staff.operator_id }).order(:id)
          @pagy, trips = pagy(scope)
          render json: { trips: trips.map { |t| OperatorTripPresenter.new(t) }, meta: pagy_meta }
        end

        def show
          render json: OperatorTripPresenter.new(@trip)
        end

        # arrival_at is never client-settable (see trip_params) -- always computed here from the
        # route's estimated_duration_minutes, per the "Est. arrival: auto, from route duration"
        # mockup. A route with no estimated_duration_minutes set (nullable column) can't schedule
        # a trip until that's fixed -- rejected with a clear 422, not silently falling back to an
        # explicit arrival_at param the UI never offers. Deliberately NOT a Trip model callback --
        # would clash with an existing regression test that builds a deliberately invalid
        # arrival_at.
        def create
          route = Route.find_by(id: trip_params[:route_id])
          return render json: { error: "Route not found" }, status: :not_found if route.nil?

          trip = route.trips.build(trip_params.except(:route_id))
          arrival_at = compute_arrival_at(route, trip.departure_at)
          if arrival_at.nil?
            return render json: { errors: { arrival_at: [ "can't be computed: route has no estimated_duration_minutes set" ] } }, status: :unprocessable_entity
          end
          trip.arrival_at = arrival_at

          authorize trip

          result = nil
          ActiveRecord::Base.transaction { result = Trips::Schedule.call!(trip: trip) }
          render json: OperatorTripPresenter.new(result.trip), status: :created
        end

        def update
          # Guarded before assignment, not left to `belongs_to :route`'s "must exist" validation,
          # because TripPolicy#same_operator? dereferences trip.route.operator_id -- a nil route
          # would NoMethodError inside authorize instead of cleanly 404ing.
          if trip_params[:route_id].present?
            new_route_id = trip_params[:route_id].to_i
            if new_route_id != @trip.route_id && !Route.exists?(new_route_id)
              return render json: { error: "Route not found" }, status: :not_found
            end
          end

          @trip.assign_attributes(trip_params)
          authorize @trip if @trip.route_id_changed?

          if @trip.route_id_changed? || @trip.departure_at_changed?
            arrival_at = compute_arrival_at(@trip.route, @trip.departure_at)
            if arrival_at.nil?
              return render json: { errors: { arrival_at: [ "can't be computed: route has no estimated_duration_minutes set" ] } }, status: :unprocessable_entity
            end
            @trip.arrival_at = arrival_at
          end

          if @trip.bus_unit_id_changed?
            result = nil
            ActiveRecord::Base.transaction { result = Trips::ChangeBusUnit.call!(trip: @trip) }
            return render json: OperatorTripPresenter.new(result.trip)
          end

          if @trip.save
            render json: OperatorTripPresenter.new(@trip)
          else
            render json: { errors: @trip.errors.as_json }, status: :unprocessable_entity
          end
        end

        def destroy
          if @trip.destroy
            head :no_content
          else
            render json: { errors: @trip.errors.as_json }, status: :unprocessable_entity
          end
        end

        private

        def set_trip
          @trip = Trip.find_by(id: params[:id])
          return render json: { error: "Trip not found" }, status: :not_found if @trip.nil?
          authorize @trip
        end

        def compute_arrival_at(route, departure_at)
          return nil if route.nil? || departure_at.nil? || route.estimated_duration_minutes.nil?

          departure_at + route.estimated_duration_minutes.minutes
        end

        def trip_params
          params.permit(:route_id, :bus_unit_id, :departure_at, :status)
        end

        def pagy_meta
          { page: @pagy.page, pages: @pagy.pages, count: @pagy.count }
        end
      end
    end
  end
end
