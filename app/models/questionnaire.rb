class Questionnaire < ApplicationRecord

  # need to add Active Record associations HERE

  validates :name, presence: true, uniqueness: {message: 'Questionnaire names must be unique.'}
  validates :min_question_score, numericality: true,
            comparison: { greater_than_or_equal_to: 0, message: 'The minimum question score must be a positive integer.'}
  validates :max_question_score, numericality: true
  # validations to ensure max_question_score is  greater than both min_question_score and 0
  validates_comparison_of :max_question_score, {greater_than: :min_question_score, message: 'The minimum question score must be less than the maximum.'}
  validates_comparison_of :max_question_score, {greater_than: 0, message: 'The maximum question score must be a positive integer greater than 0.'}

end
