class AddJoinTeamRequestToParticipants < ActiveRecord::Migration[6.0]
  def change
    add_reference :participants, :join_team_request, foreign_key: true
  end
end
