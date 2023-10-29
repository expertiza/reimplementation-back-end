# frozen_string_literal: true

class Dropdown < UnscoredQuestion

  def edit_count
    html = ''
    # Generate HTML for the edit form with the given count
    html += '<form>'
    html += "<label for='question'>Question:</label>"
    html += "<input type='text' name='question' value='Dropdown Question'>"
    html += '</form>'
    return html
  end

  def view_question_text
    if txt.nil? || type.nil? || weight.nil?
      raise ArgumentError, 'Invalid input values'
    end

    html = "<TR><TD align='left'> #{txt} </TD><TD align='left'>#{type}</TD><td align='center'>#{weight}</TD><TD align='center'>&mdash;</TD></TR>"
    return html
  end

  def complete(count, ans = nil)
    html = '<select>'
    if count
      (1..count).each do |option|
        selected = (option == answer) ? 'selected' : ''
        html << "<option value='#{option}' #{selected}>#{option}</option>"
      end
    end
    html += '</select>'
    return html
  end

  def complete_for_alternatives(alternatives, answer)
    html = '<select>'
    alternatives.each do |option|
      selected = (option == answer) ? 'selected' : ''
      html << "<option value='#{option}' #{selected}>#{option}</option>"
    end
    html += '</select>'
    return html
  end

  def view_completed_question
    html = ''
    if count && answer
      html = "Selected option: #{answer} (out of #{count})"
    else
      html = "Question not answered."
    end
    return html
  end
end
