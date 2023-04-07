class RenameSignUpTopicToSignupTopic < ActiveRecord::Migration[7.0]
  def change
    rename_table :sign_up_topics, :signup_topics
  end
end
