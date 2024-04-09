# Module QuestionHelper provides common functionalities for question-related operations
module QuestionHelper
  def edit_common(label, input_value, min_question_score, max_question_score, weight, type)
    {
      form: true,  # Indicates the presence of a form
      label: label,  # Label for the question input field
      input_type: 'text',  # Type of the input field (text)
      input_name: 'question',  # Name attribute for the input field
      input_value: input_value,  # Current value for the input field
      min_question_score: min_question_score,  # Minimum score for the question
      max_question_score: max_question_score,  # Maximum score for the question
      weight: weight,  # Weight/importance of the question
      type: type  # Type of the question
    }
  end

  def view_question_text_common(text, type, weight, score_range)
    {
      text: text,  # Text of the question
      type: type,  # Type of the question
      weight: weight,  # Weight/importance of the question
      score_range: score_range  # Score range for the question
    }
  end

end