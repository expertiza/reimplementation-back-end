# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  belongs_to :project_topic, class_name: 'ProjectTopic', foreign_key: 'topic_id', optional: true

  scope :for_questionnaire_type, lambda { |questionnaire_type|
    joins(:questionnaire).where(questionnaires: { questionnaire_type: questionnaire_type })
  }
end
