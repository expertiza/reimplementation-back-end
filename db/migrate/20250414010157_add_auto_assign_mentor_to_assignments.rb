class AddAutoAssignMentorToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :auto_assign_mentor, :boolean, default: false
  end
end
