class AddUniqueIndexOnParticipantIdToTeamsParticipants < ActiveRecord::Migration[8.0]
  def change
    # Uniqueness is enforced at model level via participant_on_team? in Team#add_member
    # A DB-level unique index on participant_id alone would prevent participants from moving between teams
  end
end
