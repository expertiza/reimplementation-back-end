# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire

  validate :weight_must_be_zero_if_no_scored_questions

  # If the linked questionnaire has no scored questions (i.e. only SectionHeaders),
  # questionnaire_weight must be 0 — a non-zero weight would produce meaningless grades.
  def weight_must_be_zero_if_no_scored_questions
    return if questionnaire.nil? || questionnaire_weight.nil? || questionnaire_weight.zero?

    has_scored = questionnaire.items.where.not(question_type: 'SectionHeader').exists?
    unless has_scored
      errors.add(:questionnaire_weight, 'must be 0 when the rubric contains no scored questions')
    end
  end
end
