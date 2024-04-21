class ChangeAssignmentIdInParticipantsTableToParentId < ActiveRecord::Migration[7.0]
  def self.up
    remove_foreign_key :participants, column: :assignment_id
    rename_column :participants, :assignment_id, :parent_id
  end

  def self.down
    rename_column :participants, :parent_id, :assignment_id
    add_foreign_key :participants, :assignment
  end
end