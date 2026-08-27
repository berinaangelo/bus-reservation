class CreateOperatorStaff < ActiveRecord::Migration[8.1]
  def change
    create_table :operator_staff do |t|
      t.references :operator, null: false, foreign_key: { on_delete: :cascade }
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :operator_staff, :email, unique: true
  end
end
