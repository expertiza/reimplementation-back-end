# frozen_string_literal: true

class AddDeadlineTypeForeignKeyToDueDates < ActiveRecord::Migration[7.0]
  def change
    # Ensure deadline_type_id column exists and is properly typed
    unless column_exists?(:due_dates, :deadline_type_id)
      add_column :due_dates, :deadline_type_id, :integer, null: false
    end

    # Clean up any invalid deadline_type_id references before adding foreign key
    reversible do |dir|
      dir.up do
        # Update any due_dates with invalid deadline_type_id to use submission (ID: 1)
        # This handles orphaned records that might reference non-existent deadline types
        execute <<~SQL
          UPDATE due_dates
          SET deadline_type_id = 1
          WHERE deadline_type_id NOT IN (1, 2, 3, 5, 6, 7, 8, 11)
          OR deadline_type_id IS NULL
        SQL

        # Clean up any duplicate team_formation references (use canonical ID 8)
        execute <<~SQL
          UPDATE due_dates
          SET deadline_type_id = 8
          WHERE deadline_type_id = 10
        SQL
      end
    end

    # Add foreign key constraint to ensure referential integrity
    add_foreign_key :due_dates, :deadline_types, column: :deadline_type_id,
                    on_delete: :restrict, on_update: :cascade

    # Add index for better query performance
    add_index :due_dates, :deadline_type_id unless index_exists?(:due_dates, :deadline_type_id)

    # Add composite index for common query patterns
    add_index :due_dates, [:parent_type, :parent_id, :deadline_type_id],
              name: 'index_due_dates_on_parent_and_deadline_type' unless
              index_exists?(:due_dates, [:parent_type, :parent_id, :deadline_type_id])
  end
end
