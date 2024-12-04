class AddAutoAssignMentorToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_column :assignments, :auto_assign_mentor, :boolean
  end
end
