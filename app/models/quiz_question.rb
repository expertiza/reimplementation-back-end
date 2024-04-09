require 'json'

# Define a base class for quiz questions, inheriting from Question
class QuizQuestion < Question
  # Establish a one-to-many relationship with quiz question choices
  # Nullify the foreign key on dependent object destruction
  has_many :quiz_question_choices, class_name: 'QuizQuestionChoice', foreign_key: 'question_id', inverse_of: false, dependent: :nullify

  # Method stub for editing a question 
  def edit
  end

  # Method to view question text along with choices and their correctness
  def view_question_text
    # Map each choice to a hash with text and correctness
    choices = quiz_question_choices.map do |choice|
      {
        text: choice.txt,  # Text of the choice
        is_correct: choice.iscorrect?  # Correctness of the choice
      }
    end

    # Construct a hash with question details and choices
    {
      question_text: txt,  # Text of the question
      question_type: type,  # Type of the question
      question_weight: weight,  # Weight/importance of the question
      choices: choices  # Choices for the question
    }.to_json  # Convert the hash to a JSON string
  end

  # Method stub for completing a question 
  def complete
  end

  # Method stub for viewing a completed question with user answers 
  def view_completed_question(user_answer = nil)
  end
end
