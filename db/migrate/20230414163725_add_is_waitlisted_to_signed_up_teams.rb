class AddIsWaitlistedToSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :signed_up_teams, :is_waitlisted, :boolean, :default => false
  end
end
