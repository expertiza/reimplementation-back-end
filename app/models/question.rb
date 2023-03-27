class Question < ApplicationRecord
  # Each question belongs to a specific questionnaire
  belongs_to :questionnaire
  has_many :question_advices
  self.inheritance_column = :_type_disabled
end