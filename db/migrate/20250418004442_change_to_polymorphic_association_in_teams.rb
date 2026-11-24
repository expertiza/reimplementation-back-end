# frozen_string_literal: true

class ChangeToPolymorphicAssociationInTeams < ActiveRecord::Migration[8.0]
  def up
    # Convert teams to a polymorphic association: drop the legacy assignment
    # reference and ensure a parent_id column is present (teams.type, added by
    # CreateTeams, distinguishes the team kinds).
    #
    # Both operations are guarded so the migration is a no-op when the columns
    # are already in the expected state:
    #   * `parent_id` is created by CreateTeams (20231102173152), so an
    #     unconditional add_column raised "Duplicate column name 'parent_id'"
    #     on a from-scratch build.
    #   * `assignment_id` may already be gone on a re-run after an interrupted run.
    remove_reference :teams, :assignment, foreign_key: true if column_exists?(:teams, :assignment_id)
    add_column :teams, :parent_id, :integer, null: false unless column_exists?(:teams, :parent_id)
  end

  def down
    remove_column :teams, :parent_id if column_exists?(:teams, :parent_id)
    add_reference :teams, :assignment, foreign_key: true unless column_exists?(:teams, :assignment_id)
  end
end

