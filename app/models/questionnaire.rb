class Questionnaire < ApplicationRecord
  has_many :questions, dependent: :destroy
  belongs_to :instructor # the creator of this questionnaire
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :assignments, through: :assignment_questionnaires
  has_one :questionnaire_node, foreign_key: 'node_object_id', dependent: :destroy, inverse_of: :questionnaire

  # ensures name is present and that the name + instructor_id combination is unique
  validates :name, presence: true, uniqueness: { scope: :instructor_id, message: 'Questionnaire names must be unique.'}
  # ensures that the min_question_score is a number greater than or equal to 0
  validates :min_question_score, numericality: true,
            comparison: { greater_than_or_equal_to: 0, message: 'The minimum question score must be a positive integer.'}
  # ensures that the max_question_score is a number
  validates :max_question_score, numericality: true
  # ensures that max_question_score is  greater than both min_question_score and 0
  validates_comparison_of :max_question_score, {greater_than: :min_question_score, message: 'The minimum question score must be less than the maximum.'}
  validates_comparison_of :max_question_score, {greater_than: 0, message: 'The maximum question score must be a positive integer greater than 0.'}

  DEFAULT_MIN_QUESTION_SCORE = 0  # The lowest score that a reviewer can assign to any questionnaire question
  DEFAULT_MAX_QUESTION_SCORE = 5  # The highest score that a reviewer can assign to any questionnaire question
  DEFAULT_QUESTIONNAIRE_URL = 'http://www.courses.ncsu.edu/csc517'.freeze
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
    # sets used_in_round to true if the associated Assignment Questionnaire has a value in the used_in_round column
    used_in_round = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id)&.used_in_round
    # sets symbol based on whether the associated Assignment Questionnaire has a value in the used_in_round column
    questionnaire_symbol = used_in_round ? "#{symbol}#{used_in_round}".to_sym : symbol
    calculate_weighted_score(assignment, questionnaire_symbol, scores)
  end

  def calculate_weighted_score(assignment, symbol, scores)
    # finds the associated assignment questionnaire and records the questionnaire_weight value
    aq = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: id)
    # finds average score based on scores passed in parameter
    avg_score = scores.dig(symbol, :scores, :avg)
    # calculates weighted score
    avg_score.nil? ? 0 : (avg_score * aq.questionnaire_weight / 100.0)
  end

  # Returns true if this questionnaire contains any true/false questions, otherwise returns false
  def has_true_false_questions
    questions.any? { |question| question.type == 'Checkbox'}
  end

  # finds the max possible score by adding the weight of each question together and multiplying that sum by the questionnaire's max question score,
  # which determines the max possible score for each question associated to the questionnaires
  def max_possible_score
    questions_weight_sum = questions.sum { |question| question.weight}
    max_score = questions_weight_sum * max_question_score
  end

  # default symbol value for calculating weight
  def symbol
    'symbol'.to_sym
  end
end
