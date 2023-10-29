# frozen_string_literal: true

class Scale < ScoredQuestion
  def edit
    html = ''
    # Generate HTML for the edit form with the given count
    html += '<form>'
    html += "<label for='question'>Question:</label>"
    html += "<input type='text' name='question' value='Scale Question'>"
    html += '</form>'
    return html
  end

  def view_question_text
    if txt.nil? || type.nil? || weight.nil?
      raise ArgumentError, 'Invalid input values'
    end

    if min_label.nil? && max_label.nil?
      score_range = "#{min_question_score} to #{max_question_score}"
    else
      score_range = "#{min_label} #{min_question_score} to #{max_question_score} #{max_label}"
    end

    html = "<TR><TD align='left'>#{txt}</TD><TD align='left'>#{type}</TD><td align='center'>#{weight}</TD><TD align='center'>#{score_range}</TD></TR>"
    return html
  end

  def complete
    html = '<select>'
    if answer
      (min_question_score..max_question_score).each do |option|
        selected = (option == answer) ? 'selected' : ''
        option_text = min_label.nil? ? option.to_s : "#{min_label} #{option} #{max_label}"
        html << "<option value='#{option}' #{selected}>#{option_text}</option>"
      end
    end
    html << '</select>'
    return html
  end

  def view_completed_question
    if count && answer && questionnaire_max
      html = "Count: #{count}, Answer: #{answer}, Questionnaire Max: #{questionnaire_max}"
    else
      html = "Question not answered."
    end
    return html
  end
end
