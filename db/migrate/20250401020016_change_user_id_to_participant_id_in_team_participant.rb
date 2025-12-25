# frozen_string_literal: true

class ChangeUserIdToParticipantIdInTeamParticipant < ActiveRecord::Migration[6.0]
  def change
    remove_column :team_participants, :user_id, :integer
    add_reference :team_participants, :participant, null: false, foreign_key: true
  end
end
