class AddTopicIdAssignmentQuestionnaire < ActiveRecord::Migration[7.0]
  def change
    add_column :assignment_questionnaires, :topic_id, :integer
  end
end
