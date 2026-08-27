module Api
  module V1
    module Operator
      class TripManifestsController < BaseController
        def show
          trip = Trip.find_by(id: params[:trip_id])
          return render json: { error: "Trip not found" }, status: :not_found if trip.nil?
          authorize trip, :show?

          @pagy, passengers = pagy(ManifestRoster.new(trip: trip).call)

          render json: {
            summary: ManifestSummary.new(trip: trip).call,
            rows: passengers.map { |p| ManifestRowPresenter.new(p) },
            meta: { page: @pagy.page, pages: @pagy.pages, count: @pagy.count }
          }
        end
      end
    end
  end
end
