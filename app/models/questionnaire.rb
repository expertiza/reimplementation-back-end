class Questionnaire < ApplicationRecord
    # for doc on why we do it this way,
    # see http://blog.hasmanythrough.com/2007/1/15/basic-rails-association-cardinality
    has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
    belongs_to :instructor, class_name: "Role" # the creator of this questionnaire
    has_many :assignments, through: :assignment_questionnaires
    
    validate :validate_questionnaire
    validates :name, presence: true
    validates :max_question_score, :min_question_score, numericality: true
  
    DEFAULT_MIN_QUESTION_SCORE = 0  # The lowest score that a reviewer can assign to any questionnaire question
    DEFAULT_MAX_QUESTION_SCORE = 5  # The highest score that a reviewer can assign to any questionnaire question
    DEFAULT_QUESTIONNAIRE_URL = 'http://www.courses.ncsu.edu/csc517'.freeze
    QUESTIONNAIRE_TYPES = ['ReviewQuestionnaire',
                           'MetareviewQuestionnaire',
                           'AuthorFeedbackQuestionnaire',
                           'TeammateReviewQuestionnaire',
                           'SurveyQuestionnaire',
                           'AssignmentSurveyQuestionnaire',
                           'GlobalSurveyQuestionnaire',
                           'CourseSurveyQuestionnaire',
                           'BookmarkRatingQuestionnaire',
                           'QuizQuestionnaire'].freeze

    # Does this questionnaire contain true/false questions?
    def true_false_questions?
      questions.each { |question| return true if question.question_type == 'Checkbox' }
      false
    end
   
    def max_possible_score
      results = Questionnaire.joins('INNER JOIN questions ON questions.questionnaire_id = questionnaires.id')
                             .select('SUM(questions.weight) * questionnaires.max_question_score as max_score')
                             .where('questionnaires.id = ?', id)
      results[0].max_score
    end
  
    # clones the contents of a questionnaire, including the questions and associated advice
    def self.copy_questionnaire_details(questionnaire_id)
      original_questionnaire = Questionnaire.find(questionnaire_id)
      questions = Question.where(questionnaire_id: questionnaire_id)
      copy_questionnaire = original_questionnaire.dup
      copy_questionnaire.name = 'Copy of ' + original_questionnaire.name
      copy_questionnaire.created_at = Time.zone.now
      copy_questionnaire.save!
      questions.each do |question|
        new_question = question.dup
        new_question.questionnaire_id = questionnaire_id
        new_question.size = '50,3' # if (new_question.is_a?(Criterion) || new_question.is_a?(TextResponse)) && new_question.size.nil?
        new_question.save! 
      end
      copy_questionnaire
    end
  
    # validate the entries for this questionnaire
    def validate_questionnaire
      errors.add(:max_question_score, 'The maximum question score must be a positive integer.') if max_question_score < 1
      errors.add(:min_question_score, 'The minimum question score must be a positive integer.') if min_question_score < 0
      errors.add(:min_question_score, 'The minimum question score must be less than the maximum.') if min_question_score >= max_question_score
  
      results = Questionnaire.where('id <> ? and name = ? and instructor_id = ?', id, name, instructor_id)
      errors.add(:name, 'Questionnaire names must be unique.') if results.present?
    end
  end
  