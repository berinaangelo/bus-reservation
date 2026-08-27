module Api
  module V1
    module Operator
      class SessionsController < BaseController
        skip_before_action :authenticate_operator_staff!, only: :create

        def create
          form = OperatorLoginForm.new(session_params)
          return render json: { errors: form.errors.as_json }, status: :unprocessable_entity unless form.valid?

          staff = OperatorStaff.find_by(email: form.email)
          if staff.nil? || !staff.active? || !staff.authenticate(form.password)
            return render json: { error: "Incorrect email or password" }, status: :unauthorized
          end

          session, raw_token = OperatorSession.issue_for(staff)
          render json: {
            token: raw_token,
            expires_at: session.expires_at.iso8601,
            operator_staff: { id: staff.id, name: staff.name, email: staff.email, operator_id: staff.operator_id }
          }, status: :created
        end

        def destroy
          current_operator_session.destroy!
          head :no_content
        end

        private

        def session_params
          params.permit(:email, :password)
        end
      end
    end
  end
end
