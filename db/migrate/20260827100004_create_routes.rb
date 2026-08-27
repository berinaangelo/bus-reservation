class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.references :operator, null: false, foreign_key: { on_delete: :restrict }
      t.references :origin_terminal, null: false, foreign_key: { to_table: :terminals, on_delete: :restrict }
      t.references :destination_terminal, null: false, foreign_key: { to_table: :terminals, on_delete: :restrict }
      t.decimal :distance_km, precision: 6, scale: 2
      t.integer :estimated_duration_minutes

      t.timestamps
    end

    add_index :routes, [ :operator_id, :origin_terminal_id, :destination_terminal_id ],
              unique: true, name: "index_routes_on_operator_and_terminal_pair"
    add_index :routes, [ :origin_terminal_id, :destination_terminal_id ], name: "index_routes_on_terminal_pair"
  end
end
