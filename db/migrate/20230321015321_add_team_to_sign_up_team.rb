class AddTeamToSignUpTeam < ActiveRecord::Migration[7.0]
  def change
    add_reference :sign_up_teams, :teams, null: false, foreign_key: true
  end
end
