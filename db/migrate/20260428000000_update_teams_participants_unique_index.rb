# frozen_string_literal: true

class UpdateTeamsParticipantsUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :teams_participants, name: :index_teams_participants_on_participant_id_unique
    add_index :teams_participants, %i[team_id participant_id], unique: true,
                                                              name: :index_teams_participants_on_team_participant_unique
  end
end
