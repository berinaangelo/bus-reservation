module Api
  module V1
    class TripsController < ApplicationController
      def index
        missing = %i[origin_terminal_id destination_terminal_id date].select { |key| params[key].blank? }
        return render json: { error: "Missing required params: #{missing.join(', ')}" }, status: :bad_request if missing.any?

        trips = TripSearch.new(
          origin_terminal_id: params[:origin_terminal_id],
          destination_terminal_id: params[:destination_terminal_id],
          date: params[:date]
        ).call

        render json: trips.map { |trip| TripPresenter.new(trip) }
      end
    end
  end
end
