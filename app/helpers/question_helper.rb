module QuestionHelper
  def edit_common(label, input_value, min_question_score, max_question_score, weight, type)
    {
      form: true,
      label: label,
      input_type: 'text',
      input_name: 'question',
      input_value: input_value,
      min_question_score: min_question_score,
      max_question_score: max_question_score,
      weight: weight,
      type: type
    }
  end

  def view_question_text_common(text, type, weight, score_range)
    { text: text, type: type, weight: weight, score_range: score_range }
  end
end