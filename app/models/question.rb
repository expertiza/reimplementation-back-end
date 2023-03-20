class Question < ApplicationRecord
  belongs_to :questionnaire
  self.inheritance_column = :_type_disabled
end