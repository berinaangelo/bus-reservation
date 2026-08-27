module Api
  module V1
    module Operator
      class FareRulesController < BaseController
        before_action :set_fare_rule, only: [ :show, :update, :destroy ]

        def index
          authorize FareRule
          scope = FareRule.joins(:route).where(routes: { operator_id: current_operator_staff.operator_id }).order(:id)
          @pagy, fare_rules = pagy(scope)
          render json: { fare_rules: fare_rules.map { |f| OperatorFareRulePresenter.new(f) }, meta: pagy_meta }
        end

        def show
          render json: OperatorFareRulePresenter.new(@fare_rule)
        end

        def create
          route = Route.find_by(id: fare_rule_params[:route_id])
          return render json: { error: "Route not found" }, status: :not_found if route.nil?

          fare_rule = route.fare_rules.build(fare_rule_params.except(:route_id))
          authorize fare_rule

          if fare_rule.save
            render json: OperatorFareRulePresenter.new(fare_rule), status: :created
          else
            render json: { errors: fare_rule.errors.as_json }, status: :unprocessable_entity
          end
        end

        # route_id is immutable on update -- moving a fare rule to a different route would need
        # re-authorization against that route too; simplest to just not allow it here.
        def update
          if @fare_rule.update(fare_rule_params.except(:route_id))
            render json: OperatorFareRulePresenter.new(@fare_rule)
          else
            render json: { errors: @fare_rule.errors.as_json }, status: :unprocessable_entity
          end
        end

        def destroy
          if @fare_rule.destroy
            head :no_content
          else
            render json: { errors: @fare_rule.errors.as_json }, status: :unprocessable_entity
          end
        end

        private

        def set_fare_rule
          @fare_rule = FareRule.find_by(id: params[:id])
          return render json: { error: "Fare rule not found" }, status: :not_found if @fare_rule.nil?
          authorize @fare_rule
        end

        def fare_rule_params
          params.permit(:route_id, :bus_class, :base_fare, :effective_date)
        end

        def pagy_meta
          { page: @pagy.page, pages: @pagy.pages, count: @pagy.count }
        end
      end
    end
  end
end
