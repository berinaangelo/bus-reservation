class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.integer :amount, null: false # centavos
      t.integer :status, null: false, default: 0 # enum: pending_cash/collected
      t.datetime :collected_at

      t.timestamps
    end
  end
end
