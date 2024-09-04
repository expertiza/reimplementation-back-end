class Questionnaire < ApplicationRecord
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :instructor
  has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
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

  # validate the entries for this questionnaire
  def validate_questionnaire
    errors.add(:max_question_score, 'The maximum question score must be a positive integer.') if max_question_score < 1
    errors.add(:min_question_score, 'The minimum question score must be a positive integer.') if min_question_score < 0
    errors.add(:min_question_score, 'The minimum question score must be less than the maximum.') if min_question_score >= max_question_score
    results = Questionnaire.where('id <> ? and name = ? and instructor_id = ?', id, name, instructor_id)
    errors.add(:name, 'Questionnaire names must be unique.') if results.present?
  end

  # Check_for_question_associations checks if questionnaire has associated questions or not
  def check_for_question_associations
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

  # Check if the questionnaire has been started by any participant
  # "Started" means there is at least one ResponseMap record associated with the Questionnaire. This indicates that a participant has begun to respond to the questionnaire, but it does not necessarily mean the response is complete.
  def started_by_anyone?
    !ResponseMap.where(reviewed_object_id: id).empty?
  end

  # Check if the questionnaire has been started by a specific participant
  # "Started" means there is at least one ResponseMap record associated with the Questionnaire and the participant.
  def started_by?(participant)
    !ResponseMap.where(reviewed_object_id: id, reviewer_id: participant.id).empty?
  end
end
