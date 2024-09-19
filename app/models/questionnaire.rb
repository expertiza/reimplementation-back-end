class Questionnaire < ApplicationRecord
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :instructor
  has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
  before_destroy :prevent_destroy_if_questions_exist
  has_many :assignment_questionnaires, dependent: :destroy
  has_many :assignments, through: :assignment_questionnaires

  validate :validate_questionnaire
  validates :name, presence: true
  validates :max_question_score, :min_question_score, numericality: true 

  # Does this questionnaire contain true/false questions?
  def true_false_questions?
    questions.where(type: 'Checkbox').exists?
  end

  def delete
    assignments.each do |assignment|
      raise "The assignment #{assignment.name} uses this questionnaire.
            Do you want to <A href='../assignment/delete/#{assignment.id}'>delete</A> the assignment?"
    end
    questions.each(&:delete)
    destroy
  end
  
  # clones the contents of a questionnaire, including the questions and associated advice
  def self.copy(params)
    orig_questionnaire = Questionnaire.find(params[:id])
    questions = Question.where(questionnaire_id: params[:id])
    questionnaire = orig_questionnaire.dup
    questionnaire.name = 'Copy of ' + orig_questionnaire.name
    questionnaire.created_at = Time.now
    questionnaire.updated_at = Time.now
    questionnaire.save!
    questions.each do |question|
      new_question = question.dup
      new_question.questionnaire_id = questionnaire.id
      new_question.save!
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

  # Checks if questionnaire has associated questions or not
  def prevent_destroy_if_questions_exist
    if questions.any?
      raise ActiveRecord::DeleteRestrictionError.new(:base, "Cannot delete record because dependent questions exist")
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
end
