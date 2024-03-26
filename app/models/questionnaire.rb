class Questionnaire < ApplicationRecord
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :instructor
  has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
  accepts_nested_attributes_for :questions # Allows nested attributes for questions
  before_destroy :check_for_question_associations

  validate :validate_questionnaire
  validates :name, presence: true
  validates :max_question_score, :min_question_score, numericality: true

  # clones the contents of a questionnaire, including the questions and associated advice
  def self.copy_questionnaire_details(params)
    orig_questionnaire = Questionnaire.find(params[:id])
    questions = Question.where(questionnaire_id: params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.name = 'Copy of ' + orig_questionnaire.name
    questionnaire.created_at = Time.zone.now
    questionnaire.updated_at = Time.zone.now
    questionnaire.save!
    questions.each do |question|
      new_question = question.dup
      new_question.questionnaire_id = questionnaire.id
      new_question.save!
    end
    questionnaire
  end


  def validate_questionnaire
    if max_question_score.nil? || max_question_score < 1
      errors.add(:max_question_score, 'The maximum question score must be a positive integer.')
    end

    if min_question_score.nil? || min_question_score.negative?
      errors.add(:min_question_score, 'The minimum question score must be a positive integer.')
    end

    return unless min_question_score && max_question_score && min_question_score >= max_question_score

    errors.add(:min_question_score, 'The minimum question score must be less than the maximum.')

  end

  # Check_for_question_associations checks if questionnaire has associated questions or not
  def check_for_question_associations
    return unless questions.any?

    raise ActiveRecord::DeleteRestrictionError, :base

  end

  def as_json(options = {})
    super(options.merge({
                          only: %i[id name private min_question_score max_question_score created_at updated_at
                                   questionnaire_type instructor_id],
                          include: {
                            instructor: { only: %i[name email fullname password role] }
                          }
                        })).tap do |hash|
      hash['instructor'] ||= { id: nil, name: nil }
    end
  end
end
