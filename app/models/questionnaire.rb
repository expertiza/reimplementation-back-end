# frozen_string_literal: true

class Questionnaire < ApplicationRecord
  belongs_to :instructor
  has_many :items, class_name: "Item", foreign_key: "questionnaire_id", dependent: :destroy # the collection of items associated with this Questionnaire
  before_destroy :any_item_associations?

  # Subclasses declare @print_name = '...' and inherit this reader automatically.
  class << self
    attr_reader :print_name
  end

  validate :validate_questionnaire
  validates :name, presence: true
  validates :max_question_score, :min_question_score, numericality: true

  # Scored rubric subclasses must override these.
  def symbol
    raise NotImplementedError, "#{self.class}#symbol not implemented"
  end

  def get_assessments_for(_participant)
    raise NotImplementedError, "#{self.class}#get_assessments_for not implemented"
  end

  def validate_questionnaire
    errors.add(:max_question_score, 'The maximum item score must be a positive integer.') if max_question_score < 1
    errors.add(:min_question_score, 'The minimum item score must be a positive integer.') if min_question_score < 0
    errors.add(:min_question_score, 'The minimum item score must be less than the maximum.') if min_question_score >= max_question_score
    results = Questionnaire.where('id <> ? and name = ? and instructor_id = ?', id, name, instructor_id)
    errors.add(:name, 'Questionnaire names must be unique.') if results.present?
  end

  # Returns a new persisted copy of this questionnaire, including its items and their advice.
  def self.copy_questionnaire_details(params)
    orig_questionnaire = Questionnaire.find(params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.instructor_id = params[:instructor_id]
    questionnaire.name = "Copy of #{orig_questionnaire.name}"
    questionnaire.created_at = Time.zone.now
    questionnaire.save!
    orig_questionnaire.items.each { |item| item.copy(questionnaire) }
    questionnaire
  end

  # Raises an error if the questionnaire has associated items, preventing deletion.
  def any_item_associations?
    return unless items.any?

    raise ActiveRecord::DeleteRestrictionError,
          'Cannot delete questionnaire because dependent items exist'
  end

  def as_json(options = {})
    super(options.merge({
      only: %i[id name private min_item_score max_item_score created_at updated_at questionnaire_type instructor_id],
      include: {
        instructor: { only: %i[name email fullname role] }
      }
    })).tap do |hash|
      hash['instructor'] ||= { id: nil, name: nil }
    end
  end

  DEFAULT_MIN_ITEM_SCORE = 0  # The lowest score that a reviewer can assign to any questionnaire item
  DEFAULT_MAX_ITEM_SCORE = 5  # The highest score that a reviewer can assign to any questionnaire item

  QUESTIONNAIRE_TYPES = [
    'ReviewQuestionnaire',
    'AuthorFeedbackQuestionnaire',
    'BookmarkRatingQuestionnaire',
    'QuizQuestionnaire',
    'SurveyQuestionnaire',
    'CourseEvaluationQuestionnaire',
    'TeammateReviewQuestionnaire',
    'GlobalSurveyQuestionnaire'
  ].freeze

  # Returns this questionnaire's weighted contribution to an assignment's overall score.
  # The scores hash (built by the assignment grading pipeline) is keyed by a symbol
  # derived from the questionnaire subclass (e.g., :review). For multi-round rubrics,
  # the round number is appended to the symbol (e.g., :review1, :review2) to
  # distinguish separate rounds of the same rubric within one assignment.
  def get_weighted_score(assignment, scores)
    round = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id).used_in_round
    questionnaire_symbol = round.nil? ? symbol : (symbol.to_s + round.to_s).to_sym
    compute_weighted_score(questionnaire_symbol, assignment, scores)
  end

  # Applies this questionnaire's weight percentage (stored in AssignmentQuestionnaire)
  # to the average response score, producing the questionnaire's weighted contribution
  # to the assignment grade. Returns 0 if no average score is available yet.
  def compute_weighted_score(symbol, assignment, scores)
    aq = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id)
    if scores[symbol][:scores][:avg].nil?
      0
    else
      scores[symbol][:scores][:avg] * aq.questionnaire_weight / 100.0
    end
  end

  # Does this questionnaire contain checkbox-type items?
  def checkbox_items?
    items.each { |question| return true if question.type == 'Checkbox' }
    false
  end

  # Sum of weights for scored items, excluding SectionHeaders.
  def total_item_weight
    items.reject { |i| i.question_type == 'SectionHeader' }.sum(&:weight)
  end

  # Calculates the maximum raw score achievable on this questionnaire:
  # (sum of all item weights) × max_item_score. This serves as the denominator
  # when normalising a response's raw score to a percentage.
  def max_possible_item_score_total
    results = Questionnaire.joins('INNER JOIN items ON items.questionnaire_id = questionnaires.id')
                           .select('SUM(items.weight) * questionnaires.max_item_score as max_score')
                           .where('questionnaires.id = ?', id)
    results[0].max_score
  end

  private

  # Shared helper used by subclasses to collect submitted responses from a set of
  # ResponseMaps that match a specific round. Extracts the inner map-iteration loop
  # that would otherwise be duplicated across ReviewQuestionnaire and
  # TeammateReviewQuestionnaire (and any future subclasses).
  def filter_submitted_responses_for_round(maps, round)
    responses = []
    maps.each do |map|
      next if map.responses.empty?

      map.responses.each do |response|
        responses << response if response.round == round && response.is_submitted
      end
    end
    responses
  end
end
