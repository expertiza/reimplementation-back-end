class AddMaxTeamSizeToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :max_team_size, :integer, null: false, default: 4
  end
end 
