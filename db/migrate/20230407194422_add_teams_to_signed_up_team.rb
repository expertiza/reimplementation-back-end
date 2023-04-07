class AddTeamsToSignedUpTeam < ActiveRecord::Migration[7.0]
  def change
    add_reference :signed_up_teams, :team, null: false, foreign_key: true
  end
end
