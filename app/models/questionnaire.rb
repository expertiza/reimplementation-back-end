class Questionnaire < ApplicationRecord
    # for doc on why we do it this way,
    # see http://blog.hasmanythrough.com/2007/1/15/basic-rails-association-cardinality
    has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
    belongs_to :instructor # the creator of this questionnaire
    
    validate :validate_questionnaire
    validates :name, presence: true
    validates :max_question_score, :min_question_score, numericality: true
  
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
    has_paper_trail

    # Does this questionnaire contain true/false questions?
    def true_false_questions?
      questions.each { |question| return true if question.type == 'Checkbox' }
      false
    end
   
    def max_possible_score
      results = Questionnaire.joins('INNER JOIN questions ON questions.questionnaire_id = questionnaires.id')
                             .select('SUM(questions.weight) * questionnaires.max_question_score as max_score')
                             .where('questionnaires.id = ?', id)
      results[0].max_score
    end
  
    # clones the contents of a questionnaire, including the questions and associated advice
    def self.copy_questionnaire_details(params, instructor_id)
      orig_questionnaire = Questionnaire.find(params[:id])
      questions = Question.where(questionnaire_id: params[:id])
      questionnaire = orig_questionnaire.dup
      questionnaire.instructor_id = instructor_id
      questionnaire.name = 'Copy of ' + orig_questionnaire.name
      questionnaire.created_at = Time.zone.now
      questionnaire.save!
      questions.each do |question|
        new_question = question.dup
        new_question.questionnaire_id = questionnaire.id
        new_question.size = '50,3' if (new_question.is_a?(Criterion) || new_question.is_a?(TextResponse)) && new_question.size.nil?
        new_question.save!
        advices = QuestionAdvice.where(question_id: question.id)
        next if advices.empty?
  
        advices.each do |advice|
          new_advice = advice.dup
          new_advice.question_id = new_question.id
          new_advice.save!
        end
      end
      questionnaire
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
  