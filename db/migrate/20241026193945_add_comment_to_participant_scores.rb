class AddCommentToParticipantScores < ActiveRecord::Migration[7.0]
  def change
    add_column :participant_scores, :comment, :text
  end
end
