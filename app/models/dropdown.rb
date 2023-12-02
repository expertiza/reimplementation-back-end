# frozen_string_literal: true

class Dropdown < UnscoredQuestion
  def edit(count)
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
    # Update with your specific logic for generating JSON
    { text: txt, type: type, weight: weight, score_range: 'N/A' }.to_json
  end

  def complete(count, answer = nil)
    options = (1..count).map { |option| { value: option, selected: (option == answer.to_i) } }
    { dropdown_options: options }.to_json
  end

  def complete_for_alternatives(alternatives, answer)
    options = alternatives.map { |alt| { value: alt, selected: (alt == answer) } }
    { dropdown_options: options }.to_json
  end

  def view_completed_question
    { selected_option: (count && answer) ? "#{answer} (out of #{count})" : 'Question not answered.' }.to_json
  end
end