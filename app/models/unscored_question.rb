# frozen_string_literal: true

class UnscoredQuestion < ChoiceQuestion
  self.table_name = 'questions'

  def edit
    {
      question_id: id,
      label: "Question #{count}:",
      input_type: 'text',
      input_id: "question_#{id}",
      input_name: "question[#{id}]",
      input_value: txt
    }.to_json
  end

  def view_question_text
    { question_text: "<p>#{txt}</p>" }.to_json
  end

  def compute
    # Compute unscored question logic and return as JSON
    { computed_result: nil }.to_json
  end

  def view_completed_question
    result = { question: "Question #{count}: #{txt}" }.to_json
    result[:answer] = answer unless answer.nil?
    result
  end
end
