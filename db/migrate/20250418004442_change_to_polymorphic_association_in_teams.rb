# frozen_string_literal: true

class ChangeToPolymorphicAssociationInTeams < ActiveRecord::Migration[8.0]
  def change
    # Remove assignment reference ONLY if it exists
    if column_exists?(:teams, :assignment_id)
      remove_reference :teams, :assignment, foreign_key: true
    end

    # Add parent_id ONLY if it does NOT already exist
    unless column_exists?(:teams, :parent_id)
      add_column :teams, :parent_id, :integer, null: false
    end
  end
end
