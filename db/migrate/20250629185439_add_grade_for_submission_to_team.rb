class AddGradeForSubmissionToTeam < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :grade_for_submission, :integer unless column_exists?(:teams, :grade_for_submission)
  end
end
