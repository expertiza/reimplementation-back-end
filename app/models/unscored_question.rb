# Inherits from ChoiceQuestion, representing a type of question that doesn't contribute to the overall score
class UnscoredQuestion < ChoiceQuestion
  # to provide the specific logic for editing an unscored question.
  def edit; end

  
  # to return the structure or content necessary to display the text of the unscored question.
  def view_question_text; end


  # to provide the specific logic required for a respondent to complete an unscored question.
  def complete; end

  # to return the structure or content necessary to display a completed unscored question, including
  # any selected answers or respondent inputs.
  def view_completed_question; end
end
