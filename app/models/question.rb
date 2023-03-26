class Question < ApplicationRecord
  # Each question belongs to a specific questionnaire
  belongs_to :questionnaire
  self.inheritance_column = :_type_disabled
end