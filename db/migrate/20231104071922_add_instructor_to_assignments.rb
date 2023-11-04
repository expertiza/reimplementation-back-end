class AddInstructorToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_reference :assignments, :instructor, null: false, foreign_key: { to_table: :users }
  end
end
