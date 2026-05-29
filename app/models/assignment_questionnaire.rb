# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire

  scope :for_assignment_and_type, ->(assignment_id, questionnaire_type) {
    joins(:questionnaire).where(assignment_id: assignment_id, questionnaires: { questionnaire_type: questionnaire_type })
  }
end
