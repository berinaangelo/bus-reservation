class CreateBusUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :bus_units do |t|
      t.string :type, null: false
      t.references :operator, null: false, foreign_key: { on_delete: :restrict }
      t.string :plate_number, null: false
      t.integer :total_seats, null: false
      t.json :seat_layout
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :bus_units, :plate_number, unique: true
    add_index :bus_units, :type
  end
end
