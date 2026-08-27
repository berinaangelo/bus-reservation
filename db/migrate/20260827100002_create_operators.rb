class CreateOperators < ActiveRecord::Migration[8.1]
  def change
    create_table :operators do |t|
      t.string :name, null: false
      t.string :franchise_number, null: false
      t.string :logo_url
      t.string :contact_info
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :operators, :franchise_number, unique: true
  end
end
