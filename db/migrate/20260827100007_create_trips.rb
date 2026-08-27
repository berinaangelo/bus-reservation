class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.references :route, null: false, foreign_key: { on_delete: :restrict }
      t.references :bus_unit, null: false, foreign_key: { on_delete: :restrict }
      t.datetime :departure_at, null: false
      t.datetime :arrival_at, null: false
      t.integer :status, null: false, default: 0 # enum: scheduled/boarding/departed/completed/cancelled
      t.integer :seats_available # running counter, OrdinaryBusUnit trips only
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :trips, [ :status, :departure_at ]
    add_index :trips, [ :departure_at, :id ], name: "index_trips_on_departure_at_and_id"
  end
end
