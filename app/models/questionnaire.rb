# frozen_string_literal: true

class Questionnaire < ApplicationRecord
  belongs_to :instructor
  has_many :items, class_name: "Item", foreign_key: "questionnaire_id", dependent: :destroy # the collection of items associated with this Questionnaire
  before_destroy :check_for_question_associations

  validate :validate_questionnaire
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
    
  # validate the entries for this questionnaire
  def validate_questionnaire
    errors.add(:max_question_score, 'The maximum item score must be a positive integer.') if max_question_score < 1
    errors.add(:min_question_score, 'The minimum item score must be a positive integer.') if min_question_score < 0
    errors.add(:min_question_score, 'The minimum item score must be less than the maximum.') if min_question_score >= max_question_score
    results = Questionnaire.where('id <> ? and name = ? and instructor_id = ?', id, name, instructor_id)
    errors.add(:name, 'Questionnaire names must be unique.') if results.present?
  end

  # clones the contents of a questionnaire, including the items and associated advice
  def self.copy_questionnaire_details(params)
    orig_questionnaire = Questionnaire.find(params[:id])
    items = Item.where(questionnaire_id: params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.instructor_id = params[:instructor_id]
    questionnaire.name = 'Copy of ' + orig_questionnaire.name
    questionnaire.created_at = Time.zone.now
    questionnaire.save!
    items.each do |question|
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

    # Check_for_question_associations checks if questionnaire has associated items or not
    def check_for_question_associations
      if items.any?
        raise ActiveRecord::DeleteRestrictionError.new( "Cannot delete record because dependent items exist")
      end
    end

    def as_json(options = {})
        super(options.merge({
                              only: %i[id name private min_question_score max_question_score created_at updated_at questionnaire_type instructor_id],
                              include: {
                                instructor: { only: %i[name email fullname password role]
                              }
                              }
                            })).tap do |hash|
          hash['instructor'] ||= { id: nil, name: nil }
        end
    end

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

    # Does this questionnaire contain true/false items?
    def true_false_items?
      items.each { |question| return true if question.type == 'Checkbox' }
      false
    end

    def max_possible_score
      results = Questionnaire.joins('INNER JOIN items ON items.questionnaire_id = questionnaires.id')
                            .select('SUM(items.weight) * questionnaires.max_question_score as max_score')
                            .where('questionnaires.id = ?', id)
      results[0].max_score
    end

  end