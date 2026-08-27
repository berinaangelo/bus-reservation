class AddBookingForeignKeyToTripSeats < ActiveRecord::Migration[8.1]
  def change
    # Bookings are cancelled via status, never hard-deleted in the normal flow — nullify is a
    # defensive fallback, not the expected path.
    add_foreign_key :trip_seats, :bookings, on_delete: :nullify
  end
end
