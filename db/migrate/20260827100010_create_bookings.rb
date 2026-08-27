class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :trip, null: false, foreign_key: { on_delete: :restrict }
      t.string :reference_code, null: false # 7 chars incl. checksum; dash-grouping is display-only
      t.integer :status, null: false, default: 0 # enum: confirmed/cancelled/no_show/completed
      t.integer :total_amount, null: false # centavos
      t.string :contact_number, null: false # shared across all passengers on this booking
      t.integer :seat_count # OrdinaryBusUnit bookings only (no seat rows to count instead)
      t.string :idempotency_key, null: false

      t.timestamps
    end

    add_index :bookings, :reference_code, unique: true
    add_index :bookings, :idempotency_key, unique: true
    add_index :bookings, :status
  end
end
