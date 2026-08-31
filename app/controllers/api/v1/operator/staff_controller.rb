module Api
  module V1
    module Operator
      # Onboards and manages OperatorStaff for the current staff member's own operator. Flat
      # authorization (any active staff can invite/manage staff) -- see OperatorStaffPolicy.
      class StaffController < BaseController
        before_action :set_staff, only: [ :update ]

        def index
          authorize OperatorStaff
          @pagy, staff = pagy(current_operator_staff.operator.operator_staff.order(:id))
          render json: { staff: staff.map { |s| OperatorStaffPresenter.new(s) }, meta: pagy_meta }
        end

        # Invites a new staff member: creates the record with a random, never-communicated
        # password (nobody types this in) and emails a set-password link reusing the password
        # reset token/mailer infrastructure -- "set your initial password" is the same flow as
        # "reset your password".
        def create
          form = OperatorStaffInviteForm.new(staff_params)
          return render json: { errors: form.errors.as_json }, status: :unprocessable_entity unless form.valid?

          staff = current_operator_staff.operator.operator_staff.build(
            name: form.name,
            email: form.email,
            password: SecureRandom.hex(32)
          )
          authorize staff

          if staff.save
            _token, raw_token = PasswordResetToken.issue_for(staff)
            OperatorStaffMailer.invite(staff, raw_token).deliver_now
            render json: OperatorStaffPresenter.new(staff), status: :created
          else
            render json: { errors: staff.errors.as_json }, status: :unprocessable_entity
          end
        end

        # Deactivating revokes access immediately (existing sessions are destroyed), mirroring what
        # a password reset already does on password change.
        def update
          if @staff.update(active_params)
            @staff.operator_sessions.destroy_all unless @staff.active?
            render json: OperatorStaffPresenter.new(@staff)
          else
            render json: { errors: @staff.errors.as_json }, status: :unprocessable_entity
          end
        end

        private

        def set_staff
          @staff = OperatorStaff.find_by(id: params[:id])
          return render json: { error: "Staff not found" }, status: :not_found if @staff.nil?
          authorize @staff
        end

        def staff_params
          params.permit(:name, :email)
        end

        def active_params
          params.permit(:active)
        end

        def pagy_meta
          { page: @pagy.page, pages: @pagy.pages, count: @pagy.count }
        end
      end
    end
  end
end
