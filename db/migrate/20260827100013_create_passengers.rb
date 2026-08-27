class CreatePassengers < ActiveRecord::Migration[8.1]
  def change
    create_table :passengers do |t|
      t.references :booking, null: false, foreign_key: { on_delete: :cascade }
      # nullable: set for reservable-class bookings (one passenger per seat), null for
      # OrdinaryBusUnit bookings (no seat rows to attach to). MySQL unique indexes treat NULL
      # as distinct, so many null rows coexist — the constraint only bites on a shared seat.
      t.references :trip_seat, null: true, foreign_key: { on_delete: :restrict }, index: { unique: true }
      t.string :full_name, null: false

      t.timestamps
    end
  end
end
