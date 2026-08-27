class CreateTerminals < ActiveRecord::Migration[8.1]
  def change
    create_table :terminals do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.string :province
      t.string :address

      t.timestamps
    end

    add_index :terminals, :name, unique: true
  end
end
