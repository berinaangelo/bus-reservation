module Api
  module V1
    module Operator
      class PaymentsController < BaseController
        def update
          payment = Payment.find_by(id: params[:id])
          return render json: { error: "Payment not found" }, status: :not_found if payment.nil?
          authorize payment, :update?
          return render json: { error: "Missing required param: collected" }, status: :bad_request if params[:collected].nil?

          collected = ActiveModel::Type::Boolean.new.cast(params[:collected])
          # Captured before the interactor runs -- Payments::SetCollected itself no-ops if
          # already in the target state, so this is the only reliable way to know whether
          # anything actually changed and a broadcast is warranted.
          already_in_target_state = payment.status == (collected ? "collected" : "pending_cash")

          result = nil
          ActiveRecord::Base.transaction do
            result = Payments::SetCollected.call!(payment: payment, collected: collected)
          end

          ManifestChannel.broadcast_to(result.payment.booking.trip, { type: "payment_collected" }) unless already_in_target_state

          render json: PaymentPresenter.new(result.payment)
        end
      end
    end
  end
end
