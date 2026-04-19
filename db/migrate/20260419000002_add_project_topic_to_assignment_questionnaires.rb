class AddProjectTopicToAssignmentQuestionnaires < ActiveRecord::Migration[8.0]
  def change
    add_reference :assignment_questionnaires, :project_topic, foreign_key: true, null: true
    add_index :assignment_questionnaires,
              %i[assignment_id project_topic_id used_in_round],
              name: 'index_aq_on_assignment_topic_round'
  end
end
