# Define a class for quiz question choices, inheriting from ApplicationRecord
class QuizQuestionChoice < ApplicationRecord
  # Establish a belongs-to relationship with a quiz question
  # Specifies that the quiz question choice is dependent on the question,
  # meaning if the question is destroyed, this choice will also be destroyed
  belongs_to :question, dependent: :destroy
end
