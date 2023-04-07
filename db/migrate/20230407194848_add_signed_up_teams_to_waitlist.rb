class AddSignedUpTeamsToWaitlist < ActiveRecord::Migration[7.0]
  def change
    add_reference :waitlists, :signed_up_team, null: false, foreign_key: true
  end
end
