module Api
  module V1
    module Operator
      class BusUnitsController < BaseController
        before_action :set_bus_unit, only: [ :show, :update, :destroy ]

        def index
          authorize BusUnit
          @pagy, bus_units = pagy(current_operator_staff.operator.bus_units.order(:id))
          render json: { bus_units: bus_units.map { |b| OperatorBusUnitPresenter.new(b) }, meta: pagy_meta }
        end

        def show
          render json: OperatorBusUnitPresenter.new(@bus_unit)
        end

        def create
          klass = BusUnit.class_for_bus_class(params[:bus_class])
          bus_unit = klass.new(bus_unit_params)
          bus_unit.operator = current_operator_staff.operator
          authorize bus_unit

          if bus_unit.save
            render json: OperatorBusUnitPresenter.new(bus_unit), status: :created
          else
            render json: { errors: bus_unit.errors.as_json }, status: :unprocessable_entity
          end
        end

        # Class-switch: `becomes!` returns a new-class instance sharing the same underlying
        # attributes (including id, operator_id), with `type` already marked changed -- one
        # #save persists both the class switch and any other field changes atomically. No
        # special-case guard is needed for the reservable<->ordinary invariant: OrdinaryBusUnit's
        # `validates :seat_layout, absence: true` and ReservableBusUnit's `presence: true` on the
        # same column already reject an incompatible switch via normal validation.
        def update
          bus_unit = @bus_unit
          if params[:bus_class].present?
            requested_class = BusUnit.class_for_bus_class(params[:bus_class])
            bus_unit = bus_unit.becomes!(requested_class) if requested_class != bus_unit.class
          end
          bus_unit.assign_attributes(bus_unit_params)

          if bus_unit.save
            render json: OperatorBusUnitPresenter.new(bus_unit)
          else
            render json: { errors: bus_unit.errors.as_json }, status: :unprocessable_entity
          end
        end

        def destroy
          if @bus_unit.destroy
            head :no_content
          else
            render json: { errors: @bus_unit.errors.as_json }, status: :unprocessable_entity
          end
        end

        private

        def set_bus_unit
          @bus_unit = BusUnit.find_by(id: params[:id])
          return render json: { error: "Bus unit not found" }, status: :not_found if @bus_unit.nil?
          authorize @bus_unit
        end

        # seat_layout's shape (rows/columns, or lower/upper for double-deck) isn't formally typed
        # anywhere else in this app either -- `{}` permits an arbitrary nested hash, matching that
        # existing looseness rather than inventing new strictness here.
        def bus_unit_params
          params.permit(:plate_number, :total_seats, :active, seat_layout: {})
        end

        def pagy_meta
          { page: @pagy.page, pages: @pagy.pages, count: @pagy.count }
        end
      end
    end
  end
end
