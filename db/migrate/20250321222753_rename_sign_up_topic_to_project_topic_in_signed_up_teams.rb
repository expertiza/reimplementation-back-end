class RenameSignUpTopicToProjectTopicInSignedUpTeams < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:signed_up_teams, :sign_up_topic_id)
      rename_column :signed_up_teams, :sign_up_topic_id, :project_topic_id
    end  
    
    if index_exists?(:signed_up_teams, :index_signed_up_teams_on_sign_up_topic_id)
      rename_index :signed_up_teams, 
                   :index_signed_up_teams_on_sign_up_topic_id, 
                   :index_signed_up_teams_on_project_topic_id
    end
  end
end
