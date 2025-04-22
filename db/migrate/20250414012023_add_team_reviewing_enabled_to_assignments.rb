class AddTeamReviewingEnabledToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :team_reviewing_enabled, :boolean, default: false
  end
end
