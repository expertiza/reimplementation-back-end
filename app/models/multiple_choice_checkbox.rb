require 'json'

# Define a class for multiple-choice checkbox questions, inheriting from QuizQuestion
class MultipleChoiceCheckbox < QuizQuestion

  # Method to prepare data for editing a question
  def edit
    # Fetch choices associated with this question
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)

    # Construct a hash with question data and its choices
    data = {
      id: id,  # Question ID
      question_text: txt,  # Question text
      weight: weight,  # Question weight
      choices: quiz_question_choices.each_with_index.map do |choice, index|
        # Map each choice to a hash with choice details
        {
          id: choice.id,  # Choice ID
          text: choice.txt,  # Choice text
          is_correct: choice.iscorrect,  # Indicates if the choice is correct
          position: index + 1  # Position of the choice
        }
      end
    }

    # Convert the hash to a JSON string
    data.to_json
  end

  # Method to prepare data for completing a question
  def complete
    # Fetch choices associated with this question
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)

    # Construct a hash with question data and its choices (without correct answers)
    data = {
      id: id,  # Question ID
      question_text: txt,  # Question text
      choices: quiz_question_choices.map do |choice|
        # Map each choice to a hash with only the choice text
        { text: choice.txt }
      end
    }

    # Convert the hash to a JSON string
    data.to_json
  end

  # Method to display a completed question along with user answers
  def view_completed_question(user_answer)
    # Fetch choices associated with this question
    quiz_question_choices = QuizQuestionChoice.where(question_id: id)

    # Construct a hash with the choices and user answers
    data = {
      question_choices: quiz_question_choices.map do |choice|
        # Map each choice to a hash with choice details and correct status
        {
          text: choice.txt,
          is_correct: choice.iscorrect
        }
      end,
      user_answers: user_answer.map do |answer|
        # Map each user answer to a hash with its correctness and comments
        {
          is_correct: answer.answer == 1,
          comments: answer.comments
        }
      end
    }

    # Convert the hash to a JSON string
    data.to_json
  end

  # Method to validate a choice selection for the question
  def isvalid(choice_info)
    error_message = nil
    # Ensure the question text is not blank
    error_message = 'Please make sure all questions have text' if txt.blank?

    # Count the number of correct answers
    correct_count = choice_info.count { |_idx, value| value[:iscorrect] == '1' }

    # Set error messages based on the number of correct answers
    if correct_count.zero?
      error_message = 'Please select a correct answer for all questions'
    elsif correct_count == 1
      error_message = 'A multiple-choice checkbox question should have more than one correct answer.'
    end

    # Return a hash indicating whether the choices are valid and any error message
    { valid: error_message.nil?, error: error_message }.to_json
  end
end
