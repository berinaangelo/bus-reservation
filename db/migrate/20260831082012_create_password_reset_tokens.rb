class CreatePasswordResetTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :password_reset_tokens do |t|
      t.references :operator_staff, null: false, foreign_key: { to_table: :operator_staff, on_delete: :cascade }
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :password_reset_tokens, :token_digest, unique: true
  end
end
