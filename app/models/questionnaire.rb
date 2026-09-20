# frozen_string_literal: true

class Questionnaire < ApplicationRecord
  belongs_to :instructor
  # the collection of items associated with this Questionnaire
  has_many :items, class_name: 'Item', foreign_key: 'questionnaire_id', dependent: :destroy
  before_destroy :any_item_associations?

  validate :validate
  validates :name, presence: true
  validates :max_question_score, :min_question_score, numericality: true

  # after_initialize :post_initialization
  # @print_name = 'Review Rubric'

  # class << self
  #   attr_reader :print_name
  # end

  # def post_initialization
  #   self.display_type = 'Review'
  # end

  def symbol
    'review'.to_sym
  end

  def get_assessments_for(participant)
    participant.reviews
  end

  # Validates min < max and name uniqueness per instructor.
  def validate
    if min_question_score >= max_question_score
      errors.add(:min_question_score, 'The minimum item score must be less than the maximum.')
    end
    duplicate_questionnaire = Questionnaire.where('id <> ? and name = ? and instructor_id = ?', id, name, instructor_id)
    errors.add(:name, 'Questionnaire names must be unique.') if duplicate_questionnaire.present?
  end

  # Returns a new persisted copy of this questionnaire, including items and advice.
  def self.copy(params)
    orig_questionnaire = Questionnaire.find(params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.instructor_id = params[:instructor_id]
    questionnaire.name = "Copy of #{orig_questionnaire.name}"
    questionnaire.created_at = Time.zone.now
    questionnaire.save!
    orig_questionnaire.items.each { |item| item.copy(questionnaire) }
    questionnaire
  end

  # Raises an error if the questionnaire has associated items.
  def any_item_associations?
    return unless items.any?

    raise ActiveRecord::DeleteRestrictionError,
          'Cannot delete questionnaire because at least one assignment uses it.'
  end

  def as_json(options = {})
    super(options.merge(
      only: %i[id name private min_question_score max_question_score
               created_at updated_at questionnaire_type instructor_id],
      include: {
        instructor: { only: %i[username name email role] }
      }
    )).tap do |hash|
      hash['instructor'] ||= { id: nil, name: nil }
    end
  end

  DEFAULT_MIN_ITEM_SCORE = 0  # The lowest score that a reviewer can assign to any item
  DEFAULT_MAX_ITEM_SCORE = 5  # The highest score that a reviewer can assign to any item
  QUESTIONNAIRE_TYPES = ['ReviewQuestionnaire',
                         'MetareviewQuestionnaire',
                         'Author FeedbackQuestionnaire',
                         'AuthorFeedbackQuestionnaire',
                         'Teammate ReviewQuestionnaire',
                         'TeammateReviewQuestionnaire',
                         'SurveyQuestionnaire',
                         'AssignmentSurveyQuestionnaire',
                         'Assignment SurveyQuestionnaire',
                         'Global SurveyQuestionnaire',
                         'GlobalSurveyQuestionnaire',
                         'Course SurveyQuestionnaire',
                         'CourseSurveyQuestionnaire',
                         'Bookmark RatingQuestionnaire',
                         'BookmarkRatingQuestionnaire',
                         'QuizQuestionnaire'].freeze
  # has_paper_trail

  def get_weighted_score(assignment, scores)
    # create symbol for "varying rubrics" feature -Yang
    round = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id).used_in_round
    questionnaire_symbol = if round.nil?
                             symbol
                           else
                             (symbol.to_s + round.to_s).to_sym
                           end
    compute_weighted_score(questionnaire_symbol, assignment, scores)
  end

  def compute_weighted_score(symbol, assignment, scores)
    # aq = assignment_questionnaires.find_by(assignment_id: assignment.id)
    aq = AssignmentQuestionnaire.find_by(assignment_id: assignment.id)

    if scores[symbol][:scores][:avg].nil?
      0
    else
      scores[symbol][:scores][:avg] * aq.questionnaire_weight / 100.0
    end
  end

  # Does this questionnaire contain checkbox-type items?
  def checkbox_items?
    items.each { |item| return true if item.type == 'Checkbox' }
    false
  end

  def max_possible_item_score_total
    score_rows = Questionnaire.joins('INNER JOIN items ON items.questionnaire_id = questionnaires.id')
                              .select('SUM(items.weight) * questionnaires.max_question_score as max_score')
                              .where('questionnaires.id = ?', id)
    score_rows[0].max_score
  end
end
