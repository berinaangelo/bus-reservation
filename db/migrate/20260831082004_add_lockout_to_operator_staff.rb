class AddLockoutToOperatorStaff < ActiveRecord::Migration[8.1]
  def change
    add_column :operator_staff, :failed_attempts, :integer, default: 0, null: false
    add_column :operator_staff, :locked_at, :datetime
  end
end
