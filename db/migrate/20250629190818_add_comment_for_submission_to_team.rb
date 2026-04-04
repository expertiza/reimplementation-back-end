class AddCommentForSubmissionToTeam < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:teams, :name)
      add_column :teams, :comment_for_submission, :string
    end
  end
end
