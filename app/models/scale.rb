# frozen_string_literal: true

class Scale < ScoredQuestion

  attr_accessor :txt, :type, :weight, :min_label, :max_label, :answer
  attr_reader :min_question_score, :max_question_score

  def edit
    html = ''
    html += '<form>'
    html += "<label for='question'>Question:</label>"
    html += "<input type='text' name='question' value='Scale Question'>"
    html += '</form>'
    return html
  end

  def view_question_text
    if txt.nil? || type.nil? || weight.nil?
      raise ArgumentError, 'Invalid input values (given 0, expected 1)'
    end

    if min_label.nil? && max_label.nil?
      score_range = "#{@min_question_score} to #{@max_question_score}"
    else
      score_range = "#{min_label} #{@min_question_score} to #{@max_question_score} #{max_label}"
    end

    "#{txt} (#{type}, #{weight}, #{score_range})"
  end

  def complete
    html = '<select>'
    if answer
      (@min_question_score..@max_question_score).each do |option|
        selected = (option == answer) ? 'selected' : ''
        option_text = min_label.nil? ? option.to_s : "#{min_label} #{option} #{max_label}"
        html << "<option value='#{option}' #{selected}>#{option_text}</option>"
      end
    end
    html += '</select>'
  end

  def view_completed_question(options = {})    #initially nil
    if options[:count] && options[:answer] && options[:questionnaire_max]
      html = "Count: #{options[:count]}, Answer: #{options[:answer]}, Questionnaire Max: #{options[:questionnaire_max]}"
    else
      html = "Question not answered."
    end
    return html
  end
end
