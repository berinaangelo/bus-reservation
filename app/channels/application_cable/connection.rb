module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_operator_staff

    def connect
      self.current_operator_staff = authenticate_operator_staff!
    end

    private

    # Browsers can't set an Authorization header on a raw WebSocket handshake (see
    # app/controllers/api/v1/operator/base_controller.rb for the REST-side equivalent), so the
    # client passes the bearer token as a query param on the /cable URL instead:
    # wss://.../cable?token=<raw_token>. Same OperatorSession.authenticate lookup either way.
    def authenticate_operator_staff!
      session = OperatorSession.authenticate(request.params[:token])
      session&.operator_staff || reject_unauthorized_connection
    end
  end
end
