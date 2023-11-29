class AddHasTeamsToAssignments < ActiveRecord::Migration[7.0]
  def change
    add_column :assignments, :has_teams, :boolean
  end
end
