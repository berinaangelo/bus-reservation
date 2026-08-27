class CreateTripSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :trip_seats do |t|
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.references :seat, null: false, foreign_key: { on_delete: :restrict }
      t.integer :status, null: false, default: 0 # enum: available/held/booked
      t.datetime :held_until
      # booking_id: column + index only for now. The FK is added once the bookings table
      # exists (see AddBookingForeignKeyToTripSeats) — bookings.trip_id depends on trips,
      # which is created before bookings, so this FK can't be declared until bookings does.
      t.bigint :booking_id

      t.timestamps
    end

    add_index :trip_seats, [ :trip_id, :seat_id ], unique: true
    add_index :trip_seats, :booking_id
    add_index :trip_seats, [ :status, :held_until ]
    add_index :trip_seats, [ :trip_id, :status ]
  end
end
