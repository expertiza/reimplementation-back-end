class Scale < ScoredQuestion
  include QuestionHelper

  attr_accessor :txt, :type, :weight, :min_label, :max_label, :answer, :min_question_score, :max_question_score

  def edit
    edit_common('Question:', 'Scale Question', min_question_score, max_question_score , weight, type).to_json
  end

  def view_question_text
    view_question_text_common(txt, type, weight, score_range).to_json
  end

  def complete
    options = (@min_question_score..@max_question_score).map do |option|
      { value: option, selected: (option == answer) }
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