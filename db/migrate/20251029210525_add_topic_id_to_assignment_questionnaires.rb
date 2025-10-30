class AddTopicIdToAssignmentQuestionnaires < ActiveRecord::Migration[8.0]
  def change
    add_column :assignment_questionnaires, :topic_id, :bigint
    add_index :assignment_questionnaires, :topic_id
    add_foreign_key :assignment_questionnaires, :sign_up_topics, column: :topic_id
  end
end