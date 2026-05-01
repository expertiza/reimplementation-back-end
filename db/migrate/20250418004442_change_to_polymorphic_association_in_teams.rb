# frozen_string_literal: true

class ChangeToPolymorphicAssociationInTeams < ActiveRecord::Migration[8.0]
  def change
    # Remove old assignment reference if it still exists
    if column_exists?(:teams, :assignment_id)
      if foreign_key_exists?(:teams, :assignments)
        remove_reference :teams, :assignment, foreign_key: true
      else
        remove_reference :teams, :assignment, foreign_key: false
      end
    end

    # Add polymorphic association fields (type column already exists)
    add_column :teams, :parent_id, :integer, null: false unless column_exists?(:teams, :parent_id)
  end
end
