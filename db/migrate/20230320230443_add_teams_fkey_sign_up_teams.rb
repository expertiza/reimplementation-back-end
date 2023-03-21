class AddTeamsFkeySignUpTeams < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :teams
  end
end
