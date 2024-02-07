# frozen_string_literal: true

class ScoredQuestion < ChoiceQuestion
  self.table_name = 'questions'

  def scorable?
    true
  end

  def edit
    {
      question_id: id,
      label: "Question #{count}:",
      input_type: 'text',
      input_id: "question_#{id}",
      input_name: "question[#{id}]",
      input_value: txt,
      weight_name: "weight[#{id}]",
      weight_value: weight
    }.to_json
  end

  def view_question_text
    # You may need to adjust the JSON structure based on your requirements
    {
      question_text: txt,
      type: nil, # Update with the actual type value
      weight: weight,
      score_range: nil # Update with the actual score range value
    }.to_json
  end

  def compute
    score = (weight.to_i * 2) # Adjust your scoring logic here
    { score: score }.to_json
  end

  def view_completed_question
    result = { question: "Question #{count}: #{txt}" }.to_json
    result[:answer] = answer unless answer.nil?
    result[:score] = compute[:score]
    result
  end

  def self.compute_question_score
    # Compute scored question score logic and return as JSON
    { computed_score: nil }.to_json
  end
end