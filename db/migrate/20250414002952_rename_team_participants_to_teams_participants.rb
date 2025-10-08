# frozen_string_literal: true

class RenameTeamParticipantsToTeamsParticipants < ActiveRecord::Migration[8.0]
  def change
    rename_table :team_participants, :teams_participants
  end
end
