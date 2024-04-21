class ChangeAssignmentIdInTeamsTableToParentId < ActiveRecord::Migration[7.0]
  def self.up
    remove_foreign_key :teams, column: :assignment_id
    rename_column :teams, :assignment_id, :parent_id
  end

  def self.down
    rename_column :teams, :parent_id, :assignment_id
    add_foreign_key :teams, :assignment
  end
end