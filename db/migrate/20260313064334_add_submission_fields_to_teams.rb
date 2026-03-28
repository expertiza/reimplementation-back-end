class AddSubmissionFieldsToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :submitted_hyperlinks, :text unless column_exists?(:teams, :submitted_hyperlinks)
    add_column :teams, :grade_for_submission, :integer unless column_exists?(:teams, :grade_for_submission)
    add_column :teams, :comment_for_submission, :string unless column_exists?(:teams, :comment_for_submission)
  end
end
