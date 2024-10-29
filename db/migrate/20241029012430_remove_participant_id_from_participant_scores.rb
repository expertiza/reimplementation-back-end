class RemoveParticipantIdFromParticipantScores < ActiveRecord::Migration[7.0]
  def change
    remove_column :participant_scores, :participant_id, :bigint
  end
end
