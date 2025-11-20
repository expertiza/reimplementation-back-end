# frozen_string_literal: true

class CreateDeadlineRights < ActiveRecord::Migration[7.0]
  def change
    create_table :deadline_rights do |t|
      t.string :name, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :deadline_rights, :name, unique: true

    # Seed the deadline rights with canonical data
    reversible do |dir|
      dir.up do
        deadline_rights = [
          { id: 1, name: 'No', description: 'Action is not allowed' },
          { id: 2, name: 'Late', description: 'Action is allowed with late penalty' },
          { id: 3, name: 'OK', description: 'Action is allowed without penalty' }
        ]

        deadline_rights.each do |right_attrs|
          execute <<~SQL
            INSERT INTO deadline_rights (id, name, description, created_at, updated_at)
            VALUES (#{right_attrs[:id]}, '#{right_attrs[:name]}', '#{right_attrs[:description]}', NOW(), NOW())
            ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            description = VALUES(description),
            updated_at = NOW()
          SQL
        end
      end

      dir.down do
        # Remove all deadline rights
        execute "DELETE FROM deadline_rights"
      end
    end
  end
end
