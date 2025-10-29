# frozen_string_literal: true

# frozen_string_literal: true

class SignUpTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'topic_id', dependent: :destroy
  has_many :teams, through: :signed_up_teams
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  has_many :due_dates, as: :parent, class_name: 'DueDate', dependent: :destroy
  belongs_to :assignment
  belongs_to :questionnaire, optional: true

  # Get the rubric/questionnaire for this topic
  # Falls back to the default assignment rubric if no topic-specific rubric exists
  def rubric_for_review(round = nil)
    # First, try to find a topic-specific rubric
    topic_questionnaire = assignment_questionnaires.find_by(
      assignment_id: assignment_id,
      used_in_round: round
    )&.questionnaire

    return topic_questionnaire if topic_questionnaire.present?

    # Fall back to the default assignment rubric
    assignment.questionnaires.find_by(
      assignment_questionnaires: { used_in_round: round }
    )
  end

  # Check if this topic has a specific rubric assigned
  def has_specific_rubric?(round = nil)
    assignment_questionnaires.exists?(
      assignment_id: assignment_id,
      used_in_round: round
    )
  end
end
