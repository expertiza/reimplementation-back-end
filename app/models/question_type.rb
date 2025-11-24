class QuestionType < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true

  # Associations (if any later)
  # has_many :questionnaires, foreign_key: :questionnaire_type, primary_key: :name
end
