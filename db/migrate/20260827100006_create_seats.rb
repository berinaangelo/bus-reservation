class CreateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :seats do |t|
      t.references :bus_unit, null: false, foreign_key: { on_delete: :cascade }
      t.string :seat_number, null: false
      t.integer :seat_type, null: false # enum: window/aisle
      t.integer :deck # enum: lower/upper, null for single-deck buses

      t.timestamps
    end

    add_index :seats, [ :bus_unit_id, :seat_number ], unique: true
  end
end
