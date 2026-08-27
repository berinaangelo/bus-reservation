module Api
  module V1
    module Operator
      # Shared base for every operator-admin controller. Provides bearer-token authentication
      # against OperatorSession and the current staff/session for the request. SessionsController
      # skips authenticate_operator_staff! for its own create action -- logging in has to work
      # without a token.
      class BaseController < ApplicationController
        before_action :authenticate_operator_staff!

        private

        def authenticate_operator_staff!
          render json: { error: "Not authenticated" }, status: :unauthorized if current_operator_session.nil?
        end

        def current_operator_session
          @current_operator_session ||= OperatorSession.authenticate(bearer_token)
        end

        def current_operator_staff
          @current_operator_staff ||= current_operator_session&.operator_staff
        end

        def bearer_token
          request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
        end

        # Pundit::Authorization (included in ApplicationController) calls this to get the acting
        # user for authorize/policy_scope -- see kos/decisions/rails-pundit-for-authorization.md.
        # There's no unified User model in this app; OperatorStaff is the Pundit user for every
        # operator-admin policy.
        def pundit_user
          current_operator_staff
        end
      end
    end
  end
end
