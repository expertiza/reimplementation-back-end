class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  # has_paper_trail

  scope :retrieve_questionnaire_for_assignment, lambda { |assignment_id|
    joins(:questionnaire).where('assignment_questionnaires.assignment_id = ?', assignment_id)
  }

  # Method to find the most recent created_at record and return that record's assignment and round
  def self.get_latest_assignment(questionnaire_id)
    record = includes(:assignment).where(questionnaire_id: questionnaire_id).order('assignments.created_at').last
    return record.assignment, record.used_in_round unless record.nil?
  end

  # E2218
  # @param assignment_id [Integer]
  # @return questions corresponding to the assignment_id and review questionnaire questions that are not headers
  def self.get_questions_by_assignment_id(assignment_id)
  end
end
