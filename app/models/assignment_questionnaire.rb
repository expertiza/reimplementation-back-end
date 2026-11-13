# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire

  validate :weight_must_be_zero_if_no_scored_items

  # If the linked questionnaire has scored items (i.e. not only SectionHeaders),
  # any weight is fine. If it has only SectionHeaders, weight must be 0.
  # Empty questionnaires (no items yet) are exempt — the questionnaire hasn't been
  # configured yet and blocking assignment creation at that stage is premature.
  def weight_must_be_zero_if_no_scored_items
    return if questionnaire.nil? || questionnaire_weight.nil? || questionnaire_weight.zero? || questionnaire.items.none?

    has_scored = questionnaire.items.where.not(item_type: 'SectionHeader').exists?
    unless has_scored
      errors.add(:questionnaire_weight, 'must be 0 when the rubric contains no scored items')
    end
  end
end
