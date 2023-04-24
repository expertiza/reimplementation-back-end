class Questionnaire < ApplicationRecord
  has_many :questions, dependent: :destroy # the collection of questions associated with this Questionnaire
end
