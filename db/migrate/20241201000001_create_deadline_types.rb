# frozen_string_literal: true

class CreateDeadlineTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :deadline_types do |t|
      t.string :name, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :deadline_types, :name, unique: true

    change_column :due_dates, :deadline_type_id, :bigint

    # Add foreign key constraint to due_dates table
    # add_foreign_key :due_dates, :deadline_types, column: :deadline_type_id

    # Seed canonical deadline type data
    reversible do |dir|
      dir.up do
        deadline_types = [
          { id: 1, name: 'submission', description: 'Student work submission deadlines' },
          { id: 2, name: 'review', description: 'Peer review deadlines' },
          { id: 3, name: 'teammate_review', description: 'Team member evaluation deadlines' },
          { id: 5, name: 'metareview', description: 'Meta-review deadlines (kept for backward compatibility)' },
          { id: 6, name: 'drop_topic', description: 'Topic drop deadlines' },
          { id: 7, name: 'signup', description: 'Course/assignment signup deadlines' },
          { id: 8, name: 'team_formation', description: 'Team formation deadlines' },
          { id: 11, name: 'quiz', description: 'Quiz completion deadlines' }
        ]

        deadline_types.each do |type_attrs|
          execute <<~SQL
            INSERT INTO deadline_types (id, name, description, created_at, updated_at)
            VALUES (#{type_attrs[:id]}, '#{type_attrs[:name]}', '#{type_attrs[:description]}', NOW(), NOW())
            ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            description = VALUES(description),
            updated_at = NOW()
          SQL
        end

        # Clean up any duplicate team_formation entries (keeping ID 8)
        execute <<~SQL
          DELETE FROM deadline_types
          WHERE name = 'team_formation' AND id != 8
        SQL

        # Update any due_dates that might reference the duplicate ID
        execute <<~SQL
          UPDATE due_dates
          SET deadline_type_id = 8
          WHERE deadline_type_id IN (
            SELECT id FROM deadline_types
            WHERE name = 'team_formation' AND id != 8
          )
        SQL
      end

      dir.down do
        # Remove foreign key constraint before dropping table
        remove_foreign_key :due_dates, :deadline_types
      end
    end
  end
end
