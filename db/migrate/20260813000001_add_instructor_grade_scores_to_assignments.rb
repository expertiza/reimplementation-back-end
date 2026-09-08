class AddInstructorGradeScoresToAssignments < ActiveRecord::Migration[7.1]
  def change
    add_column :assignments, :instructor_grade_min_score, :integer
    add_column :assignments, :instructor_grade_max_score, :integer
  end
end
