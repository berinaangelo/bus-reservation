module Api
  module V1
    class TerminalsController < ApplicationController
      # Backs the Trip Search screen's From/To autocomplete (frontend/src/components/ui/BaseAutocomplete.vue).
      # No Pundit authorize -- public/unauthenticated, same as TripsController#index.
      def index
        terminals = Terminal.order(:name)
        terminals = terminals.where("name LIKE :q OR city LIKE :q", q: "%#{params[:q]}%") if params[:q].present?

        # Bounded -- this feeds a live-typing dropdown, not a full picker.
        render json: terminals.limit(20).map { |t| TerminalPresenter.new(t) }
      end
    end
  end
end
