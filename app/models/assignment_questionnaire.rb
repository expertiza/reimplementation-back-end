# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  belongs_to :project_topic, optional: true

  validate :project_topic_belongs_to_assignment
  validate :unique_review_rubric_for_assignment_topic_round

  private

  def project_topic_belongs_to_assignment
    return if project_topic_id.blank? || assignment_id.blank?

    return if project_topic&.assignment_id == assignment_id

    errors.add(:project_topic, 'must belong to the same assignment')
  end

  def unique_review_rubric_for_assignment_topic_round
    return unless review_questionnaire?

    duplicate = AssignmentQuestionnaire
                .joins(:questionnaire)
                .where(
                  assignment_id: assignment_id,
                  project_topic_id: project_topic_id,
                  used_in_round: used_in_round,
                  questionnaires: { questionnaire_type: 'ReviewQuestionnaire' }
                )
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:base, 'review rubric already exists for this assignment, topic, and round') if duplicate.exists?
  end

  def review_questionnaire?
    questionnaire&.questionnaire_type == 'ReviewQuestionnaire'
  end
end
