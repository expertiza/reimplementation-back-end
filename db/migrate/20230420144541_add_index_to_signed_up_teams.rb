class AddIndexToSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    add_index(:signed_up_teams, [:topic_id], name: "fk_signed_up_users_sign_up_topics")
  end
end
