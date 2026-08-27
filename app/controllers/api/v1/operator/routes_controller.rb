module Api
  module V1
    module Operator
      class RoutesController < BaseController
        before_action :set_route, only: [ :show, :update, :destroy ]

        def index
          authorize Route
          @pagy, routes = pagy(current_operator_staff.operator.routes.order(:id))
          render json: { routes: routes.map { |r| OperatorRoutePresenter.new(r) }, meta: pagy_meta }
        end

        def show
          render json: OperatorRoutePresenter.new(@route)
        end

        def create
          route = current_operator_staff.operator.routes.build(route_params)
          authorize route

          if route.save
            render json: OperatorRoutePresenter.new(route), status: :created
          else
            render json: { errors: route.errors.as_json }, status: :unprocessable_entity
          end
        end

        def update
          if @route.update(route_params)
            render json: OperatorRoutePresenter.new(@route)
          else
            render json: { errors: @route.errors.as_json }, status: :unprocessable_entity
          end
        end

        def destroy
          if @route.destroy
            head :no_content
          else
            render json: { errors: @route.errors.as_json }, status: :unprocessable_entity
          end
        end

        private

        def set_route
          @route = Route.find_by(id: params[:id])
          return render json: { error: "Route not found" }, status: :not_found if @route.nil?
          authorize @route
        end

        def route_params
          params.permit(:origin_terminal_id, :destination_terminal_id, :distance_km, :estimated_duration_minutes)
        end

        def pagy_meta
          { page: @pagy.page, pages: @pagy.pages, count: @pagy.count }
        end
      end
    end
  end
end
