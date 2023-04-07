class ScoredQuestion < ChoiceQuestion
  validates :weight, presence: true # user must specify a weight for a question
  validates :weight, numericality: true # the weight must be numeric

  # This method returns what to display if an instructor (etc.) is creating or editing a questionnaire (questionnaires_controller.rb).
  def edit; end

  # This method returns what to display if an instructor (etc.) is viewing a questionnaire
  def view_question_text; end

  # Returns what to display for the complete question.
  def complete; end

  # Returns what to display if a student is viewing a filled-out questionnaire.
  def view_completed_question; end

  # Calculates the score by adding weight to the answer.
  def self.compute_question_score(response_id)
    answer = Answer.find_by(question_id: id, response_id: response_id)
    weight * answer.answer
  end
end
