class AddSignUpTopicsToSignedUpTeam < ActiveRecord::Migration[7.0]
  def change
    add_reference :signed_up_teams, :sign_up_topic, null: false, foreign_key: true
  end
end
