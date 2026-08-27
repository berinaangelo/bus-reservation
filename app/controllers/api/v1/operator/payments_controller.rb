module Api
  module V1
    module Operator
      class PaymentsController < BaseController
        def update
          payment = Payment.find_by(id: params[:id])
          return render json: { error: "Payment not found" }, status: :not_found if payment.nil?
          authorize payment, :update?
          return render json: { error: "Missing required param: collected" }, status: :bad_request if params[:collected].nil?

          result = nil
          ActiveRecord::Base.transaction do
            result = Payments::SetCollected.call!(payment: payment, collected: ActiveModel::Type::Boolean.new.cast(params[:collected]))
          end

          render json: PaymentPresenter.new(result.payment)
        end
      end
    end
  end
end
