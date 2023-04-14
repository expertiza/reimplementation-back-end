class ChangeForeignKeyForSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    rename_column :signed_up_teams, :sign_up_topic_id, :signup_topic_id
  end
end
