module Api
  module V1
    module Operator
      class PasswordResetsController < BaseController
        skip_before_action :authenticate_operator_staff!, only: [ :create, :update ]

        GENERIC_REQUEST_MESSAGE = "If that email is registered, we've sent password reset instructions."
        INVALID_TOKEN_MESSAGE = "This reset link is invalid or has expired."

        def create
          form = PasswordResetRequestForm.new(request_params)
          return render json: { errors: form.errors.as_json }, status: :unprocessable_entity unless form.valid?

          staff = OperatorStaff.find_by(email: form.email)
          if staff&.active?
            _token, raw_token = PasswordResetToken.issue_for(staff)
            OperatorStaffMailer.password_reset(staff, raw_token).deliver_now
          end

          render json: { message: GENERIC_REQUEST_MESSAGE }, status: :ok
        end

        def update
          reset_token = PasswordResetToken.authenticate(params[:token])
          return render json: { error: INVALID_TOKEN_MESSAGE }, status: :unprocessable_entity if reset_token.nil?

          form = PasswordResetForm.new(update_params)
          return render json: { errors: form.errors.as_json }, status: :unprocessable_entity unless form.valid?

          staff = reset_token.operator_staff
          staff.update!(password: form.password)
          staff.reset_lockout!
          staff.operator_sessions.destroy_all
          reset_token.destroy!

          render json: { message: "Password updated. You can now log in." }, status: :ok
        end

        private

        def request_params
          params.permit(:email)
        end

        def update_params
          params.permit(:password, :password_confirmation)
        end
      end
    end
  end
end
