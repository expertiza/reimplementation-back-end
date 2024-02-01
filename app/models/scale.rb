# frozen_string_literal: true

class Scale < ScoredQuestion
  attr_accessor :txt, :type, :weight, :min_label, :max_label, :answer
  attr_reader :min_question_score, :max_question_score

  def edit
    {
      form: true,
      label: 'Question:',
      input_type: 'text',
      input_name: 'question',
      input_value: 'Scale Question'
    }.to_json
  end

  def view_question_text
    # Update with your specific logic for generating JSON
    { text: txt, type: type, weight: weight, score_range: score_range }.to_json
  end

  def complete
    options = (@min_question_score..@max_question_score).map do |option|
      { value: option, selected: (option == answer) }.to_json
    end
    { scale_options: options }.to_json
  end

  def view_completed_question(options = {})
    if options[:count] && options[:answer] && options[:questionnaire_max]
      { count: options[:count], answer: options[:answer], questionnaire_max: options[:questionnaire_max] }.to_json
    else
      { message: 'Question not answered.' }.to_json
    end
  end

  private

  def score_range
    min_label.nil? && max_label.nil? ? "#{@min_question_score} to #{@max_question_score}" :
      "#{min_label} #{@min_question_score} to #{@max_question_score} #{max_label}"
  end
end