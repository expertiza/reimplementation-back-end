class AddUniqueIndexOnParticipantIdToTeamsParticipants < ActiveRecord::Migration[8.0]
  def change
    add_index :teams_participants, :participant_id, unique: true, name: 'index_teams_participants_on_participant_id_unique'
  end
end
