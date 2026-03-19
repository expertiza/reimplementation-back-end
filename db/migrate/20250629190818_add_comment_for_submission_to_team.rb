class AddCommentForSubmissionToTeam < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :comment_for_submission, :string
  end
end
