# frozen_string_literal: true

class ChangeToPolymorphicAssociationInTeams < ActiveRecord::Migration[8.0]
  def change
    # Remove old assignment reference (course reference doesn't exist)
    remove_reference :teams, :assignment, foreign_key: true

    # Add polymorphic association fields (type column already exists)
    return if column_exists?(:teams, :parent_id)

    add_column :teams, :parent_id, :integer, null: false
  end
end
