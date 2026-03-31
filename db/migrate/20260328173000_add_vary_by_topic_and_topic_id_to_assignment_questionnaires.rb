# frozen_string_literal: true

class AddVaryByTopicAndTopicIdToAssignmentQuestionnaires < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:assignments, :vary_by_topic)
      add_column :assignments, :vary_by_topic, :boolean, default: false, null: false
    end

    if column_exists?(:assignment_questionnaires, :topic_id)
      change_column :assignment_questionnaires, :topic_id, :bigint
    else
      add_column :assignment_questionnaires, :topic_id, :bigint
    end

    add_index :assignment_questionnaires, :topic_id unless index_exists?(:assignment_questionnaires, :topic_id)

    topic_table =
      if table_exists?(:project_topics)
        :project_topics
      elsif table_exists?(:sign_up_topics)
        :sign_up_topics
      end

    if topic_table && !foreign_key_exists?(:assignment_questionnaires, topic_table, column: :topic_id)
      add_foreign_key :assignment_questionnaires, topic_table, column: :topic_id
    end
  end
end
