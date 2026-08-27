class CreateFareRules < ActiveRecord::Migration[8.1]
  def change
    create_table :fare_rules do |t|
      t.references :route, null: false, foreign_key: { on_delete: :cascade }
      t.integer :bus_class, null: false # enum: ordinary/aircon/deluxe/double_deck
      t.integer :base_fare, null: false # centavos
      t.date :effective_date, null: false

      t.timestamps
    end

    add_index :fare_rules, [ :route_id, :bus_class, :effective_date ], name: "index_fare_rules_on_route_class_and_date"
  end
end
