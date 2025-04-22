class AddSignUpTopicIdToAssignmentQuestionnaires < ActiveRecord::Migration[8.0]
  def change
    add_column :assignment_questionnaires, :sign_up_topic_id, :integer
  end
end
