class RenameSignUpTopicsToProjectTopics < ActiveRecord::Migration[7.0]
  def change
    rename_table :sign_up_topics, :project_topics
  end
end
