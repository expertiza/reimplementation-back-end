class QuestionAdvice < ApplicationRecord
  # stores Question advice details for questions within a questionnaire
  # attr_accessible :score, :advice
  belongs_to :question

end
