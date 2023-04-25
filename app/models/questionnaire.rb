class Questionnaire < ApplicationRecord
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
end
