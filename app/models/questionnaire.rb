class Questionnaire < ApplicationRecord
  validate :validate_questionnaire
  validates :name, presence: true
  validates :max_question_score, :min_question_score, numericality: true

  def validate_questionnaire
    # errors.add(:max_question_score, 'The maximum question score must be a non-zero positive integer.') if max_question_score < 1
    # errors.add(:min_question_score, 'The minimum question score must be a positive integer.') if min_question_score < 0
    # errors.add(:min_question_score, 'The minimum question score must be less than the maximum.') if min_question_score >= max_question_score

    #break this up
    results = Questionnaire.where('id <> ? and name = ? and instructor_id = ?', id, name, instructor_id)
    errors.add(:name, 'Questionnaire names must be unique.') if results.present?
    #does this match on name & instructor_id?
  end
end
